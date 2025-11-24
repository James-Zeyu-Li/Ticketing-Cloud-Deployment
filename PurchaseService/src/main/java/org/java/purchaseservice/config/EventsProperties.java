package org.java.purchaseservice.config;

import lombok.Data;
import org.java.purchaseservice.model.event.Event;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

import java.util.List;

@Data
@Configuration
@ConfigurationProperties(prefix = "events")
public class EventsProperties {
    private boolean autoInitialize;
    private List<Event> list;
}
