package org.java.purchaseservice.config;

import io.awspring.cloud.sns.core.SnsTemplate;
import io.awspring.cloud.sqs.operations.SqsTemplate;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import software.amazon.awssdk.services.sns.SnsClient;
import software.amazon.awssdk.services.sqs.SqsAsyncClient;

@Configuration
public class MessageSnsConfig {

  @Bean
  public SnsClient snsClient() {
    return SnsClient.create();
  }

  @Bean
  public SqsAsyncClient sqsAsyncClient() {
    return SqsAsyncClient.create();
  }

  @Bean
  public SnsTemplate snsTemplate(SnsClient snsClient) {
    return new SnsTemplate(snsClient);
  }

  @Bean
  public SqsTemplate sqsTemplate(SqsAsyncClient sqsAsyncClient) {
    return SqsTemplate.builder()
        .sqsAsyncClient(sqsAsyncClient)
        .build();
  }

}
