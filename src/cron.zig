//! Lightweight cron/heartbeat scheduler for KrillClaw.
//!
//! Provides interval-based task scheduling with minimal binary footprint.
//! Designed for edge devices that need periodic agent runs, data collection
//! heartbeats, or keep-alive signals between connectivity windows.
//!
//! Usage:
//!   --cron-interval 300       Run agent every 300 seconds with cron prompt
//!   --cron-prompt "check sensors and report"
//!   --heartbeat 60            Log heartbeat every 60 seconds
//!
//! Architecture:
//!   Uses POSIX timer_create or std.time for scheduling. No threads — uses
//!   a simple poll loop between agent runs. Suitable for both Lite (BLE/Serial)
//!   and Full (HTTP) profiles.

const std = @import("std");
const types = @import("types.zig");

/// Cron configuration — parsed from CLI or config file.
pub const CronConfig = struct {
    /// Interval in seconds between agent runs. 0 = disabled.
    interval_s: u32 = 0,
    /// Prompt to send to the agent on each cron tick.
    prompt: []const u8 = "heartbeat: check status and report any anomalies",
    /// Heartbeat interval in seconds. 0 = disabled. Logs a heartbeat line.
    heartbeat_s: u32 = 0,
    /// Maximum number of cron runs. 0 = unlimited.
    max_runs: u32 = 0,
};

/// Scheduler state — tracks timing for cron and heartbeat.
pub const Scheduler = struct {
    config: CronConfig,
    last_cron: i64,
    last_heartbeat: i64,
    run_count: u32,
    start_time: i64,
    stdout: std.fs.File.DeprecatedWriter,

    pub fn init(config: CronConfig) Scheduler {
        const now = std.time.timestamp();
        return .{
            .config = config,
            .last_cron = now,
            .last_heartbeat = now,
            .run_count = 0,
            .start_time = now,
            .stdout = std.fs.File.stdout().deprecatedWriter(),
        };
    }

    /// Check if it's time for a cron agent run.
    pub fn shouldRunAgent(self: *Scheduler) bool {
        if (self.config.interval_s == 0) return false;
        if (self.config.max_runs > 0 and self.run_count >= self.config.max_runs) return false;

        const now = std.time.timestamp();
        const elapsed: u64 = @intCast(now - self.last_cron);
        if (elapsed >= self.config.interval_s) {
            self.last_cron = now;
            self.run_count += 1;
            return true;
        }
        return false;
    }

    /// Check if it's time for a heartbeat log.
    pub fn shouldHeartbeat(self: *Scheduler) bool {
        if (self.config.heartbeat_s == 0) return false;

        const now = std.time.timestamp();
        const elapsed: u64 = @intCast(now - self.last_heartbeat);
        if (elapsed >= self.config.heartbeat_s) {
            self.last_heartbeat = now;
            return true;
        }
        return false;
    }

    /// Emit a heartbeat log line (lightweight, no allocation).
    pub fn emitHeartbeat(self: *Scheduler) void {
        const now = std.time.timestamp();
        const uptime: u64 = @intCast(now - self.start_time);
        self.stdout.print("[heartbeat] up:{d}s runs:{d}\n", .{ uptime, self.run_count }) catch {};
    }

    /// Get the cron prompt for this tick.
    pub fn getCronPrompt(self: *const Scheduler) []const u8 {
        return self.config.prompt;
    }

    /// Returns true if the scheduler is active (either cron or heartbeat enabled).
    pub fn isActive(self: *const Scheduler) bool {
        return self.config.interval_s > 0 or self.config.heartbeat_s > 0;
    }

    /// Sleep until the next event (cron or heartbeat), whichever comes first.
    /// Returns immediately if nothing is scheduled.
    pub fn sleepUntilNext(self: *const Scheduler) void {
        if (!self.isActive()) return;

        var min_wait: u64 = std.math.maxInt(u64);
        const now = std.time.timestamp();

        if (self.config.interval_s > 0) {
            const elapsed: u64 = @intCast(now - self.last_cron);
            const remaining = if (elapsed >= self.config.interval_s) 0 else self.config.interval_s - @as(u32, @intCast(elapsed));
            min_wait = @min(min_wait, remaining);
        }

        if (self.config.heartbeat_s > 0) {
            const elapsed: u64 = @intCast(now - self.last_heartbeat);
            const remaining = if (elapsed >= self.config.heartbeat_s) 0 else self.config.heartbeat_s - @as(u32, @intCast(elapsed));
            min_wait = @min(min_wait, remaining);
        }

        if (min_wait > 0 and min_wait < std.math.maxInt(u64)) {
            std.Thread.sleep(min_wait * std.time.ns_per_s);
        }
    }

    /// Returns true if we've hit the max run limit.
    pub fn isComplete(self: *const Scheduler) bool {
        if (self.config.max_runs == 0) return false;
        return self.run_count >= self.config.max_runs;
    }
};

/// Parse cron-related CLI arguments. Call after standard config parsing.
pub fn parseCronArgs(args_iter: anytype) CronConfig {
    var config = CronConfig{};

    while (args_iter.next()) |arg| {
        if (std.mem.eql(u8, arg, "--cron-interval")) {
            if (args_iter.next()) |val| {
                config.interval_s = std.fmt.parseInt(u32, val, 10) catch 0;
            }
        } else if (std.mem.eql(u8, arg, "--cron-prompt")) {
            if (args_iter.next()) |val| {
                config.prompt = val;
            }
        } else if (std.mem.eql(u8, arg, "--heartbeat")) {
            if (args_iter.next()) |val| {
                config.heartbeat_s = std.fmt.parseInt(u32, val, 10) catch 0;
            }
        } else if (std.mem.eql(u8, arg, "--cron-max-runs")) {
            if (args_iter.next()) |val| {
                config.max_runs = std.fmt.parseInt(u32, val, 10) catch 0;
            }
        }
    }

    return config;
}

// --- Tests ---

test "scheduler init" {
    const config = CronConfig{ .interval_s = 60, .heartbeat_s = 10 };
    const sched = Scheduler.init(config);
    try std.testing.expect(sched.isActive());
    try std.testing.expect(!sched.isComplete());
    try std.testing.expectEqual(@as(u32, 0), sched.run_count);
}

test "scheduler disabled" {
    const config = CronConfig{};
    const sched = Scheduler.init(config);
    try std.testing.expect(!sched.isActive());
}

test "shouldRunAgent respects max_runs" {
    const config = CronConfig{ .interval_s = 1, .max_runs = 2 };
    var sched = Scheduler.init(config);
    // Simulate time passing by setting last_cron in the past
    sched.last_cron = std.time.timestamp() - 2;
    try std.testing.expect(sched.shouldRunAgent());
    try std.testing.expectEqual(@as(u32, 1), sched.run_count);

    sched.last_cron = std.time.timestamp() - 2;
    try std.testing.expect(sched.shouldRunAgent());
    try std.testing.expectEqual(@as(u32, 2), sched.run_count);

    // Should not run again — hit max
    sched.last_cron = std.time.timestamp() - 2;
    try std.testing.expect(!sched.shouldRunAgent());
    try std.testing.expect(sched.isComplete());
}

test "shouldHeartbeat timing" {
    const config = CronConfig{ .heartbeat_s = 1 };
    var sched = Scheduler.init(config);
    // Just initialized — shouldn't fire yet
    try std.testing.expect(!sched.shouldHeartbeat());

    // Simulate time passing
    sched.last_heartbeat = std.time.timestamp() - 2;
    try std.testing.expect(sched.shouldHeartbeat());
}

test "getCronPrompt returns configured prompt" {
    const config = CronConfig{ .prompt = "collect sensor data" };
    const sched = Scheduler.init(config);
    try std.testing.expectEqualStrings("collect sensor data", sched.getCronPrompt());
}
