package com.freefitness.social;

import com.freefitness.common.Result;
import com.freefitness.social.dto.FriendHealthSummary;
import com.freefitness.social.entity.ChatMessage;
import com.freefitness.social.entity.SocialComment;
import com.freefitness.social.entity.SocialMoment;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@Tag(name = "Social", description = "社交模块接口 (Friends, Moments, Chat)")
@RestController
@RequestMapping("/api/v1/social")
public class SocialController {

    @Autowired
    private SocialService socialService;

    // --- Friendship ---
    @Operation(summary = "请求添加好友")
    @PostMapping("/friends/request")
    public Result<Object> requestFriend(@RequestParam Long userId, @RequestParam Long friendId) {
        return Result.success(socialService.requestFriend(userId, friendId));
    }

    @Operation(summary = "通过好友请求")
    @PostMapping("/friends/accept")
    public Result<Object> acceptFriend(@RequestParam Long userId, @RequestParam Long friendId) {
        socialService.acceptFriend(userId, friendId);
        return Result.success("Friend request accepted");
    }

    @Operation(summary = "获取好友列表")
    @GetMapping("/friends/{userId}")
    public Result<List<Long>> getFriends(@PathVariable Long userId) {
        return Result.success(socialService.getFriendIds(userId));
    }

    @Operation(summary = "获取待处理的好友请求")
    @GetMapping("/friends/pending/{userId}")
    public Result<List<Long>> getPendingRequests(@PathVariable Long userId) {
        return Result.success(socialService.getPendingRequestIds(userId));
    }

    @Operation(summary = "获取已发送的好友请求")
    @GetMapping("/friends/sent/{userId}")
    public Result<List<Long>> getSentRequests(@PathVariable Long userId) {
        return Result.success(socialService.getSentRequestIds(userId));
    }

    @Operation(summary = "获取好友健康数据摘要")
    @GetMapping("/health-summary/{friendId}")
    public Result<FriendHealthSummary> getFriendHealthSummary(@RequestParam Long userId, @PathVariable Long friendId) {
        return Result.success(socialService.getFriendHealthSummary(userId, friendId));
    }

    // --- Moments ---
    @Operation(summary = "发布动态")
    @PostMapping("/moments")
    public Result<SocialMoment> postMoment(@RequestBody SocialMoment moment) {
        return Result.success(socialService.postMoment(moment));
    }

    @Operation(summary = "获取朋友圈时间线")
    @GetMapping("/moments/timeline/{userId}")
    public Result<List<SocialMoment>> getTimeline(@PathVariable Long userId) {
        return Result.success(socialService.getTimeline(userId));
    }

    @Operation(summary = "发表评论")
    @PostMapping("/moments/comment")
    public Result<SocialComment> addComment(@RequestBody SocialComment comment) {
        return Result.success(socialService.addComment(comment));
    }

    @Operation(summary = "获取动态评论")
    @GetMapping("/moments/{momentId}/comments")
    public Result<List<SocialComment>> getComments(@PathVariable Long momentId) {
        return Result.success(socialService.getComments(momentId));
    }

    @Operation(summary = "点赞/取消点赞")
    @PostMapping("/moments/like")
    public Result<Object> toggleLike(@RequestParam Long userId, @RequestParam Long momentId) {
        socialService.toggleLike(userId, momentId);
        return Result.success("Operation successful");
    }

    @Operation(summary = "获取点赞用户列表")
    @GetMapping("/moments/{momentId}/likes")
    public Result<List<Long>> getLikeUserIds(@PathVariable Long momentId) {
        return Result.success(socialService.getLikeUserIds(momentId));
    }

    @Operation(summary = "检查用户是否已点赞")
    @GetMapping("/moments/{momentId}/is-liked")
    public Result<Boolean> isLikedByUser(@RequestParam Long userId, @PathVariable Long momentId) {
        return Result.success(socialService.isLikedByUser(userId, momentId));
    }

    // --- Chat ---
    @Operation(summary = "发送私聊消息")
    @PostMapping("/chat/send")
    public Result<ChatMessage> sendMessage(@RequestBody ChatMessage message) {
        return Result.success(socialService.sendMessage(message));
    }

    @Operation(summary = "获取聊天历史")
    @GetMapping("/chat/history")
    public Result<List<ChatMessage>> getChatHistory(@RequestParam Long u1, @RequestParam Long u2) {
        return Result.success(socialService.getChatHistory(u1, u2));
    }
}
