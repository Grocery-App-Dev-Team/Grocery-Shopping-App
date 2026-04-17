package com.grocery.server.chat.service;

import org.springframework.stereotype.Component;

import jakarta.annotation.PostConstruct;
import jakarta.annotation.PreDestroy;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentMap;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;

@Component
public class MessageBroadcastDeduplicator {

    private final ConcurrentMap<String, Long> seen = new ConcurrentHashMap<>();
    private final ScheduledExecutorService cleaner = Executors.newSingleThreadScheduledExecutor();

    @PostConstruct
    public void init() {
        // Remove entries older than 30 seconds periodically
        cleaner.scheduleAtFixedRate(() -> {
            long now = System.currentTimeMillis();
            seen.entrySet().removeIf(e -> now - e.getValue() > TimeUnit.SECONDS.toMillis(30));
        }, 30, 30, TimeUnit.SECONDS);
    }

    @PreDestroy
    public void shutdown() {
        cleaner.shutdownNow();
        seen.clear();
    }

    public void markProcessed(String id) {
        if (id == null) return;
        seen.put(id, System.currentTimeMillis());
    }

    public boolean isProcessed(String id) {
        if (id == null) return false;
        Long t = seen.get(id);
        return t != null && System.currentTimeMillis() - t < TimeUnit.SECONDS.toMillis(30);
    }
}
