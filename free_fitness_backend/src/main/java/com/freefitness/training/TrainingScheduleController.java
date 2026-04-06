package com.freefitness.training;

import com.freefitness.training.entity.TrainingSchedule;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/training/schedules")
@RequiredArgsConstructor
public class TrainingScheduleController {

    private final TrainingService trainingService;

    @PostMapping
    public TrainingSchedule create(@RequestBody TrainingSchedule req) {
        return trainingService.createSchedule(req);
    }

    @GetMapping("/user/{userId}")
    public List<TrainingSchedule> getByUser(@PathVariable Long userId) {
        return trainingService.getSchedules(userId);
    }

    @GetMapping("/user/{userId}/daily")
    public List<TrainingSchedule> getDaily(@PathVariable Long userId, @RequestParam String date) {
        return trainingService.getDailySchedules(userId, date);
    }

    @PutMapping("/{id}")
    public TrainingSchedule update(@PathVariable Long id, @RequestBody TrainingSchedule req) {
        return trainingService.updateSchedule(id, req);
    }

    @DeleteMapping("/{id}")
    public void delete(@PathVariable Long id) {
        trainingService.deleteSchedule(id);
    }
}
