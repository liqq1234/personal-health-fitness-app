package com.freefitness.social.entity;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@Entity
@Table(name = "ff_chat_message")
public class ChatMessage {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "message_id")
    private Long messageId;

    @Column(name = "sender_id", nullable = false)
    private Long senderId;

    @Column(name = "receiver_id", nullable = false)
    private Long receiverId;

    @Column(name = "msg_type", length = 10, nullable = false)
    private String msgType; // TEXT, IMAGE

    @Column(name = "content", columnDefinition = "TEXT")
    private String content;

    @Column(name = "gmt_create", length = 30)
    private String gmtCreate;
}
