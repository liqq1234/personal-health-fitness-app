package com.freefitness.social;

import com.freefitness.health.repository.DailyStepsRepository;
import com.freefitness.health.repository.ExerciseSessionRepository;
import com.freefitness.social.dto.FriendHealthSummary;
import com.freefitness.social.entity.ChatMessage;
import com.freefitness.social.entity.Friendship;
import com.freefitness.social.entity.SocialComment;
import com.freefitness.social.entity.SocialMoment;
import com.freefitness.social.entity.SocialLike;
import com.freefitness.social.repository.ChatMessageRepository;
import com.freefitness.social.repository.FriendshipRepository;
import com.freefitness.social.repository.SocialCommentRepository;
import com.freefitness.social.repository.SocialLikeRepository;
import com.freefitness.social.repository.SocialMomentRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class SocialService {

    @Autowired
    private FriendshipRepository friendshipRepository;

    @Autowired
    private SocialMomentRepository momentRepository;

    @Autowired
    private SocialCommentRepository commentRepository;

    @Autowired
    private ChatMessageRepository chatMessageRepository;

    @Autowired
    private SocialLikeRepository likeRepository;

    @Autowired
    private DailyStepsRepository stepsRepo;

    @Autowired
    private ExerciseSessionRepository sessionRepo;

    private static final DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    // --- Friendship ---
    public Friendship requestFriend(Long userId, Long friendId) {
        if (userId.equals(friendId)) {
            throw new RuntimeException("Cannot add yourself as a friend");
        }
        // Check if already exists (prevent duplicate entry error)
        return friendshipRepository.findByUserIdAndFriendId(userId, friendId).orElseGet(() -> {
            Friendship friendship = new Friendship();
            friendship.setUserId(userId);
            friendship.setFriendId(friendId);
            friendship.setStatus("PENDING");
            friendship.setGmtCreate(LocalDateTime.now().format(formatter));
            return friendshipRepository.save(friendship);
        });
    }

    public void acceptFriend(Long userId, Long friendId) {
        // Find the pending request (friendId is the requester, userId is the one accepting)
        friendshipRepository.findByUserIdAndFriendId(friendId, userId).ifPresent(f -> {
            f.setStatus("ACCEPTED");
            friendshipRepository.save(f);
            
            // Handle reciprocal friendship: check if exists before creating
            Friendship reciprocal = friendshipRepository.findByUserIdAndFriendId(userId, friendId)
                    .orElseGet(() -> {
                        Friendship r = new Friendship();
                        r.setUserId(userId);
                        r.setFriendId(friendId);
                        r.setGmtCreate(LocalDateTime.now().format(formatter));
                        return r;
                    });
            reciprocal.setStatus("ACCEPTED");
            friendshipRepository.save(reciprocal);
        });
    }

    public List<Long> getFriendIds(Long userId) {
        return friendshipRepository.findByUserIdAndStatus(userId, "ACCEPTED")
                .stream().map(Friendship::getFriendId).collect(Collectors.toList());
    }

    public List<Long> getPendingRequestIds(Long userId) {
        return friendshipRepository.findByFriendIdAndStatus(userId, "PENDING")
                .stream().map(Friendship::getUserId).collect(Collectors.toList());
    }

    public List<Long> getSentRequestIds(Long userId) {
        return friendshipRepository.findByUserIdAndStatus(userId, "PENDING")
                .stream().map(Friendship::getFriendId).collect(Collectors.toList());
    }

    // --- Moments ---
    public SocialMoment postMoment(SocialMoment moment) {
        moment.setGmtCreate(LocalDateTime.now().format(formatter));
        return momentRepository.save(moment);
    }

    public List<SocialMoment> getTimeline(Long userId) {
        List<Long> friendIds = getFriendIds(userId);
        friendIds.add(userId);
        return momentRepository.findByUserIdInOrderByGmtCreateDesc(friendIds);
    }

    public SocialComment addComment(SocialComment comment) {
        comment.setGmtCreate(LocalDateTime.now().format(formatter));
        return commentRepository.save(comment);
    }

    public List<SocialComment> getComments(Long momentId) {
        return commentRepository.findByMomentIdOrderByGmtCreateAsc(momentId);
    }

    public void toggleLike(Long userId, Long momentId) {
        likeRepository.findByUserIdAndMomentId(userId, momentId).ifPresentOrElse(
            likeRepository::delete,
            () -> likeRepository.save(new SocialLike(userId, momentId, LocalDateTime.now().format(formatter)))
        );
    }

    public long getLikeCount(Long momentId) {
        return likeRepository.countByMomentId(momentId);
    }

    public List<Long> getLikeUserIds(Long momentId) {
        return likeRepository.findByMomentIdOrderByGmtCreateAsc(momentId)
                .stream().map(SocialLike::getUserId).collect(Collectors.toList());
    }

    public boolean isLikedByUser(Long userId, Long momentId) {
        return likeRepository.findByUserIdAndMomentId(userId, momentId).isPresent();
    }

    // --- Chat ---
    public ChatMessage sendMessage(ChatMessage message) {
        message.setGmtCreate(LocalDateTime.now().format(formatter));
        return chatMessageRepository.save(message);
    }

    public List<ChatMessage> getChatHistory(Long u1, Long u2) {
        return chatMessageRepository.findChatHistory(u1, u2);
    }

    public FriendHealthSummary getFriendHealthSummary(Long userId, Long friendId) {
        // 1. Verify friendship
        boolean isFriend = friendshipRepository.findByUserIdAndFriendId(userId, friendId)
                .filter(f -> "ACCEPTED".equals(f.getStatus()))
                .isPresent();
        if (!isFriend) return new FriendHealthSummary(0L, 0.0, 0.0, 0);

        // 2. Fetch data for last 7 days
        String endDate = LocalDate.now().toString();
        String startDate = LocalDate.now().minusDays(6).toString();

        long totalSteps = stepsRepo.findByUserIdAndDateBetweenOrderByDateAsc(friendId, startDate, endDate)
                .stream().mapToLong(com.freefitness.health.entity.DailySteps::getSteps).sum();

        var sessions = sessionRepo.findByUserIdAndStartTimeBetweenOrderByStartTimeAsc(friendId, startDate + "T00:00:00", endDate + "T23:59:59");
        double totalDist = sessions.stream().mapToDouble(s -> s.getDistance() / 1000.0).sum();
        double totalCals = sessions.stream().mapToDouble(s -> s.getCalories() != null ? s.getCalories() : 0.0).sum();
        
        long activeDays = sessions.stream().map(s -> s.getStartTime().substring(0, 10)).distinct().count();

        return new FriendHealthSummary(totalSteps, totalDist, totalCals, (int) activeDays);
    }
}
