package org.java.purchaseservice.bootstrap;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.java.purchaseservice.config.EventsProperties;
import org.java.purchaseservice.model.event.Event;
import org.java.purchaseservice.service.initialize.VenueConfigService;
import org.java.purchaseservice.service.redis.SeatOccupiedService;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.stereotype.Component;

@Slf4j
@Component
@RequiredArgsConstructor
public class RedisSeatBootstrap implements ApplicationRunner {

	private final SeatOccupiedService seatOccupiedService;
	private final EventsProperties eventsProperties;
	private final VenueConfigService venueConfigService;

	@Override
	public void run(ApplicationArguments args) {
		if (!eventsProperties.isAutoInitialize()) {
			log.info("[RedisSeatBootstrap] Auto-initialization of seats is disabled. Skipping.");
			return;
		}

		log.info("[RedisSeatBootstrap] Starting seat initialization for all configured events...");
		if (eventsProperties.getList() == null || eventsProperties.getList().isEmpty()) {
			log.warn("[RedisSeatBootstrap] No events found in configuration. Skipping seat initialization.");
			return;
		}

		int initializedCount = 0;
		for (Event event : eventsProperties.getList()) {
			if (!event.isEnabled()) {
				log.debug("[RedisSeatBootstrap] Skipping disabled event: {}", event.getEventId());
				continue;
			}

			String eventId = event.getEventId();
			String venueId = event.getVenueId();

			if (venueId == null || venueId.trim().isEmpty()) {
				log.warn("[RedisSeatBootstrap] Skipping event '{}': venueId is missing.", eventId);
				continue;
			}

			if (!venueConfigService.isVenueExists(venueId)) {
				log.warn("[RedisSeatBootstrap] Skipping event '{}': Venue '{}' is not configured or initialized.", eventId, venueId);
				continue;
			}

			try {
				log.info("[RedisSeatBootstrap] Initializing seats for event '{}' at venue '{}'.", eventId, venueId);
				seatOccupiedService.initializeAllZonesForEvent(eventId, venueId);
				initializedCount++;
			} catch (Exception e) {
				log.error("[RedisSeatBootstrap] Failed to initialize seats for event '{}': {}", eventId, e.getMessage(), e);
			}
		}

		log.info("[RedisSeatBootstrap] Finished seat initialization. Total events initialized: {}", initializedCount);
	}
}
