package com.freefitness.system.repository;

import com.freefitness.system.entity.Backup;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface BackupRepository extends JpaRepository<Backup, String> {
    List<Backup> findByUserIdOrderBySavedAtDesc(Long userId);
}
