package org.java.purchaseservice.model.event;

import lombok.Data;

@Data
public class Event {
    private String eventId;
    private String name;
    private String type;
    private String date;
    private String venueId;
    private boolean enabled;
}
