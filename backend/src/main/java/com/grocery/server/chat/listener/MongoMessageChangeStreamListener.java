package com.grocery.server.chat.listener;

import com.grocery.server.chat.dto.MessageResponse;
import com.grocery.server.chat.document.Message;
import com.grocery.server.chat.service.MessageBroadcastDeduplicator;
import com.grocery.server.chat.repository.ConversationRepository;
import com.grocery.server.user.repository.UserRepository;
import com.mongodb.client.MongoCursor;
import com.mongodb.client.MongoClient;
import com.mongodb.client.MongoCollection;
import com.mongodb.client.MongoDatabase;
import com.mongodb.client.model.Aggregates;
import com.mongodb.client.model.Filters;
import com.mongodb.client.model.changestream.ChangeStreamDocument;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.bson.Document;
import org.bson.conversions.Bson;
import org.bson.types.ObjectId;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Component;

import jakarta.annotation.PostConstruct;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.Arrays;
import java.util.Date;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@Component
@RequiredArgsConstructor
@Slf4j
public class MongoMessageChangeStreamListener {

    private final MongoClient mongoClient;
    private final SimpMessagingTemplate messagingTemplate;
    private final ConversationRepository conversationRepository;
    private final UserRepository userRepository;
    private final MessageBroadcastDeduplicator deduplicator;

    @Value("${spring.data.mongodb.database:grocery_chat}")
    private String databaseName;

    @PostConstruct
    public void start() {
        Thread t = new Thread(this::watch, "mongo-change-stream-watcher");
        t.setDaemon(true);
        t.start();
    }

    private void watch() {
        try {
            MongoDatabase db = mongoClient.getDatabase(databaseName);
            MongoCollection<Document> coll = db.getCollection("messages");
            List<Bson> pipeline = Arrays.asList(Aggregates.match(Filters.in("operationType", Arrays.asList("insert"))));

            try (MongoCursor<ChangeStreamDocument<Document>> cursor = coll.watch(pipeline).iterator()) {
                while (cursor.hasNext()) {
                    ChangeStreamDocument<Document> change = cursor.next();
                    Document full = change.getFullDocument();
                    if (full == null) continue;

                    String id = null;
                    Object _id = full.get("_id");
                    if (_id instanceof ObjectId) id = ((ObjectId) _id).toHexString();
                    else if (_id != null) id = _id.toString();
                    if (id == null) continue;

                    if (deduplicator.isProcessed(id)) {
                        log.debug("Skipping already-processed message id {}", id);
                        continue;
                    }

                    MessageResponse response = mapDocumentToMessageResponse(full, id);
                    String conversationId = response.getConversationId();

                    // Broadcast to subscribers for this conversation
                    messagingTemplate.convertAndSend("/topic/chat/conversation/" + conversationId, response);

                    // Notify conversation list update for involved users
                    conversationRepository.findById(conversationId).ifPresent(conv -> {
                        Optional.ofNullable(conv.getShipperId()).ifPresent(shId -> userRepository.findById(shId)
                                .ifPresent(user -> messagingTemplate.convertAndSendToUser(
                                        user.getPhoneNumber(),
                                        "/queue/chat/conversations",
                                        Map.of("conversationId", conv.getId(), "event", "conversation_updated")
                                )));

                        Optional.ofNullable(conv.getCustomerId()).ifPresent(cId -> userRepository.findById(cId)
                                .ifPresent(user -> messagingTemplate.convertAndSendToUser(
                                        user.getPhoneNumber(),
                                        "/queue/chat/conversations",
                                        Map.of("conversationId", conv.getId(), "event", "conversation_updated")
                                )));
                    });
                }
            }
        } catch (Exception ex) {
            log.error("Error in MongoDB change stream listener", ex);
            try { Thread.sleep(5000); } catch (InterruptedException ignored) {}
            watch();
        }
    }

    private MessageResponse mapDocumentToMessageResponse(Document full, String id) {
        var builder = MessageResponse.builder().id(id);

        builder.conversationId(full.getString("conversationId"));

        Object senderIdObj = full.get("senderId");
        if (senderIdObj instanceof Number) {
            builder.senderId(((Number) senderIdObj).longValue());
        } else if (senderIdObj != null) {
            try { builder.senderId(Long.parseLong(senderIdObj.toString())); } catch (NumberFormatException ignored) {}
        }

        String senderType = full.getString("senderType");
        if (senderType != null) {
            try { builder.senderType(Message.SenderType.valueOf(senderType)); } catch (IllegalArgumentException ignored) {}
        }

        builder.content(full.getString("content"));
        Date ts = full.getDate("timestamp");
        if (ts != null) {
            builder.timestamp(LocalDateTime.ofInstant(ts.toInstant(), ZoneId.systemDefault()));
        }
        builder.read(Boolean.TRUE.equals(full.getBoolean("read")));
        return builder.build();
    }
}
