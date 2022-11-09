
const std = @import("std");
const MessageDispatcher = @import("engine/message-queue.zig").MessageDispatcher;
const DirMon = @import("state-machines/dirmon.zig").DirMon;

fn help() void {
    std.debug.print("Usage\n", .{});
    std.debug.print("{s} <directory-to-monitor>\n", .{std.os.argv[0]});
}

pub fn main() !void {

    if (2 != std.os.argv.len) {
        help();
        return;
    }

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    //defer print("leakage?.. {}\n", .{gpa.deinit()});
    const allocator = gpa.allocator();

    var md = try MessageDispatcher.onStack(allocator, 5);
    var dm = try DirMon.onHeap(allocator, &md, std.mem.sliceTo(std.os.argv[1], 0));
    try dm.run();
    try md.loop();
    md.eq.fini();
}
