package com.freefitness.social.entity;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@Entity
@Table(name = "ff_social_like", uniqueConstraints = {
    @UniqueConstraint(columnNames = {"moment_id", "user_id"})
})
public class SocialLike {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long likeId;

    @Column(name = "moment_id", nullable = false)
    private Long momentId;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(name = "gmt_create", length = 30)
    private String gmtCreate;

    public SocialLike(Long userId, Long momentId, String gmtCreate) {
        this.userId = userId;
        this.momentId = momentId;
        this.gmtCreate = gmtCreate;
    }
}
