package com.freefitness.user;

import com.freefitness.common.service.FileStorageService;
import com.freefitness.user.dto.UpdateUserRequest;
import com.freefitness.user.dto.WeightTrendRequest;
import com.freefitness.user.dto.WeightTrendResponse;
import com.freefitness.user.entity.IntakeDailyGoal;
import com.freefitness.user.entity.User;
import com.freefitness.user.entity.WeightTrend;
import com.freefitness.user.repository.IntakeDailyGoalRepository;
import com.freefitness.user.repository.UserRepository;
import com.freefitness.user.repository.WeightTrendRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.stream.Collectors;

/**
 * 用户信息管理服务：1.5 ~ 1.8
 */
@Service
@RequiredArgsConstructor
public class UserService {

    private final UserRepository userRepository;
    private final WeightTrendRepository weightTrendRepository;
    private final IntakeDailyGoalRepository intakeDailyGoalRepository;
    private final FileStorageService storageService;

    @Value("${storage.avatar-dir}")
    private String avatarDir;

    private static final DateTimeFormatter FMT = DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss");

    // ───── 1.5 查询 / 更新用户信息 ─────

    public User getUser(Long userId) {
        return userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("用户不存在：" + userId));
    }

    @Transactional
    public User updateUser(Long userId, UpdateUserRequest req) {
        User user = getUser(userId);
        if (req.getUserName()       != null) user.setUserName(req.getUserName());
        if (req.getGender()         != null) user.setGender(req.getGender());
        if (req.getDateOfBirth()    != null) user.setDateOfBirth(req.getDateOfBirth());
        if (req.getHeight()         != null) user.setHeight(req.getHeight());
        if (req.getHeightUnit()     != null) user.setHeightUnit(req.getHeightUnit());
        if (req.getCurrentWeight()  != null) user.setCurrentWeight(req.getCurrentWeight());
        if (req.getTargetWeight()   != null) user.setTargetWeight(req.getTargetWeight());
        if (req.getWeightUnit()     != null) user.setWeightUnit(req.getWeightUnit());
        if (req.getDescription()    != null) user.setDescription(req.getDescription());
        if (req.getRdaGoal()        != null) user.setRdaGoal(req.getRdaGoal());
        if (req.getProteinGoal()    != null) user.setProteinGoal(req.getProteinGoal());
        if (req.getFatGoal()        != null) user.setFatGoal(req.getFatGoal());
        if (req.getChoGoal()        != null) user.setChoGoal(req.getChoGoal());
        if (req.getActionRestTime() != null) user.setActionRestTime(req.getActionRestTime());
        user.setGmtModified(LocalDateTime.now().format(FMT));
        return userRepository.save(user);
    }

    // ───── 1.6 上传头像 ─────

    @Transactional
    public String uploadAvatar(Long userId, MultipartFile file) throws IOException {
        User user = getUser(userId);
        // 使用统一存储服务
        String url = storageService.storeFile(file, avatarDir, "/uploads/avatars/");
        user.setAvatar(url);
        user.setGmtModified(LocalDateTime.now().format(FMT));
        userRepository.save(user);
        return url;
    }

    // ───── 1.7 体重趋势 ─────

    @Transactional
    public WeightTrendResponse addWeightTrend(Long userId, WeightTrendRequest req) {
        WeightTrend wt = new WeightTrend();
        wt.setUserId(userId);
        // CryptoConverter 将后台自动加解密
        wt.setWeight(req.getWeight());
        wt.setWeightUnit(req.getWeightUnit());
        wt.setHeight(req.getHeight());
        wt.setHeightUnit(req.getHeightUnit());
        wt.setBmi(req.getBmi());
        wt.setGmtCreate(req.getGmtCreate() != null ? req.getGmtCreate() : LocalDateTime.now().format(FMT));
        wt = weightTrendRepository.save(wt);
        return toWeightTrendResponse(wt);
    }

    public List<WeightTrendResponse> getWeightTrends(Long userId, String startDate, String endDate) {
        List<WeightTrend> list;
        if (startDate != null && endDate != null) {
            list = weightTrendRepository.findByUserIdAndGmtCreateBetweenOrderByGmtCreateAsc(
                    userId, startDate, endDate);
        } else {
            list = weightTrendRepository.findTop30ByUserIdOrderByGmtCreateDesc(userId);
        }
        return list.stream().map(this::toWeightTrendResponse).collect(Collectors.toList());
    }

    private WeightTrendResponse toWeightTrendResponse(WeightTrend wt) {
        WeightTrendResponse resp = new WeightTrendResponse();
        resp.setWeightTrendId(wt.getWeightTrendId());
        resp.setUserId(wt.getUserId());
        // CryptoConverter 将后台自动解密，此处直接获取
        resp.setWeight(wt.getWeight());
        resp.setWeightUnit(wt.getWeightUnit());
        resp.setHeight(wt.getHeight());
        resp.setHeightUnit(wt.getHeightUnit());
        resp.setBmi(wt.getBmi());
        resp.setGmtCreate(wt.getGmtCreate());
        return resp;
    }

    // ───── 1.8 每日摄入目标 ─────

    public List<IntakeDailyGoal> getIntakeGoals(Long userId) {
        return intakeDailyGoalRepository.findByUserId(userId);
    }

    @Transactional
    public List<IntakeDailyGoal> upsertIntakeGoals(Long userId, List<IntakeDailyGoal> goals) {
        for (IntakeDailyGoal goal : goals) {
            goal.setUserId(userId);
            intakeDailyGoalRepository.findByUserIdAndDayOfWeek(userId, goal.getDayOfWeek())
                    .ifPresent(existing -> goal.setIntakeDailyGoalId(existing.getIntakeDailyGoalId()));
            intakeDailyGoalRepository.save(goal);
        }
        return intakeDailyGoalRepository.findByUserId(userId);
    }
}
