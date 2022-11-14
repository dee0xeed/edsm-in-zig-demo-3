
const std = @import("std");
const os = std.os;
const print = std.debug.print;
const Allocator = std.mem.Allocator;

const mq = @import("../engine/message-queue.zig");
const MessageDispatcher = mq.MessageDispatcher;
const MessageQueue = MessageDispatcher.MessageQueue;
const Message = MessageQueue.Message;
const esrc = @import("../engine//event-sources.zig");
const EventSource = esrc.EventSource;
const edsm = @import("../engine/edsm.zig");
const StageMachine = edsm.StageMachine;

const util = @import("../util.zig");

pub const DirMon = struct {

    const M0_WORK = Message.M0;

    const DirMonData = struct {
        sg0: EventSource,
        sg1: EventSource,
        fs0: EventSource,
        dir: []const u8,
    };

    pub fn onHeap(a: Allocator, md: *MessageDispatcher, dir: []const u8) !*StageMachine {
        var me = try StageMachine.onHeap(a, md, "DirMon", 1, DirMonData);
        try me.addStage(.{.name = "INIT", .enter = &initEnter, .leave = null});
        try me.addStage(.{.name = "WORK", .enter = &workEnter, .leave = &workLeave});

        var init = &me.stages.items[0];
        var work = &me.stages.items[1];

        init.setReflex(.sm, Message.M0, .{.transition = work});

        work.setReflex(.fs, Message.F00, .{.action = &workF00});
        work.setReflex(.fs, Message.F01, .{.action = &workF01});
        work.setReflex(.fs, Message.F02, .{.action = &workF02});
        work.setReflex(.fs, Message.F03, .{.action = &workF03});
        work.setReflex(.fs, Message.F04, .{.action = &workF04});
        work.setReflex(.fs, Message.F05, .{.action = &workF05});
        work.setReflex(.fs, Message.F06, .{.action = &workF06});
        work.setReflex(.fs, Message.F07, .{.action = &workF07});
        work.setReflex(.fs, Message.F08, .{.action = &workF08});
        work.setReflex(.fs, Message.F09, .{.action = &workF09});
        work.setReflex(.fs, Message.F10, .{.action = &workF10});
        work.setReflex(.fs, Message.F11, .{.action = &workF11});
        work.setReflex(.fs, Message.F12, .{.action = &workF12});
        work.setReflex(.fs, Message.F13, .{.action = &workF13});
        work.setReflex(.fs, Message.F14, .{.action = &workF14});
        work.setReflex(.fs, Message.F15, .{.action = &workF15});

        work.setReflex(.sg, Message.S0, .{.action = &workS0});
        work.setReflex(.sg, Message.S1, .{.action = &workS0});

        var pd = util.opaqPtrTo(me.data, *DirMonData);
        pd.dir = dir;
        return me;
    }

    fn initEnter(me: *StageMachine) void {
        var pd = util.opaqPtrTo(me.data, *DirMonData);
        me.initSignal(&pd.sg0, os.SIG.INT, Message.S0) catch unreachable;
        me.initSignal(&pd.sg1, os.SIG.TERM, Message.S1) catch unreachable;
        me.initFsys(&pd.fs0) catch unreachable;
        me.msgTo(me, M0_WORK, null);
    }

    fn workEnter(me: *StageMachine) void {
        var pd = util.opaqPtrTo(me.data, *DirMonData);
        const mask: u32 = 0xFFF; // get them all
        pd.fs0.addWatch(pd.dir, mask) catch unreachable;
        pd.fs0.enable(&me.md.eq, .{}) catch unreachable;
        pd.sg0.enable(&me.md.eq, .{}) catch unreachable;
        pd.sg1.enable(&me.md.eq, .{}) catch unreachable;
    }

    fn workF00(me: *StageMachine, src: ?*StageMachine, dptr: ?*anyopaque) void {
        _ = src;
        var pd = util.opaqPtrTo(me.data, *DirMonData);
        var fs = util.opaqPtrTo(dptr, *EventSource);
        if ((fs.info.fs.event.mask & 0x40000000) == 0) {
            print("'{s}': accessed\n", .{fs.info.fs.fname});
        } else {
            print("'{s}': accessed\n", .{pd.dir});
        }
        fs.enable(&me.md.eq, .{}) catch unreachable;
    }

    fn workF01(me: *StageMachine, src: ?*StageMachine, dptr: ?*anyopaque) void {
        _ = src;
        var pd = util.opaqPtrTo(me.data, *DirMonData);
        _ = pd;
        var fs = util.opaqPtrTo(dptr, *EventSource);
        print("'{s}': modifiled\n", .{fs.info.fs.fname});
        fs.enable(&me.md.eq, .{}) catch unreachable;
    }

    fn workF02(me: *StageMachine, src: ?*StageMachine, dptr: ?*anyopaque) void {
        _ = src;
        var pd = util.opaqPtrTo(me.data, *DirMonData);
        _ = pd;
        var fs = util.opaqPtrTo(dptr, *EventSource);
        print("'{s}': metadata changed\n", .{fs.info.fs.fname});
        fs.enable(&me.md.eq, .{}) catch unreachable;
    }

    fn workF03(me: *StageMachine, src: ?*StageMachine, dptr: ?*anyopaque) void {
        _ = src;
        var pd = util.opaqPtrTo(me.data, *DirMonData);
        _ = pd;
        var fs = util.opaqPtrTo(dptr, *EventSource);
        print("'{s}': closed (write)\n", .{fs.info.fs.fname});
        fs.enable(&me.md.eq, .{}) catch unreachable;
    }

    fn workF04(me: *StageMachine, src: ?*StageMachine, dptr: ?*anyopaque) void {
        _ = src;
        var pd = util.opaqPtrTo(me.data, *DirMonData);
        var fs = util.opaqPtrTo(dptr, *EventSource);
        if ((fs.info.fs.event.mask & 0x40000000) == 0) {
            print("'{s}': closed (read)\n", .{fs.info.fs.fname});
        } else {
            print("'{s}': closed (read)\n", .{pd.dir});
        }
        fs.enable(&me.md.eq, .{}) catch unreachable;
    }

    fn workF05(me: *StageMachine, src: ?*StageMachine, dptr: ?*anyopaque) void {
        _ = src;
        var pd = util.opaqPtrTo(me.data, *DirMonData);
        var fs = util.opaqPtrTo(dptr, *EventSource);
        if ((fs.info.fs.event.mask & 0x40000000) == 0) {
            print("'{s}': opened\n", .{fs.info.fs.fname});
        } else {
            print("'{s}': opened\n", .{pd.dir});
        }
        fs.enable(&me.md.eq, .{}) catch unreachable;
    }

    fn workF06(me: *StageMachine, src: ?*StageMachine, dptr: ?*anyopaque) void {
        _ = src;
        var pd = util.opaqPtrTo(me.data, *DirMonData);
        var fs = util.opaqPtrTo(dptr, *EventSource);
        print("'{s}': moved from '{s}'\n", .{fs.info.fs.fname, pd.dir});
        fs.enable(&me.md.eq, .{}) catch unreachable;
    }

    fn workF07(me: *StageMachine, src: ?*StageMachine, dptr: ?*anyopaque) void {
        _ = src;
        var pd = util.opaqPtrTo(me.data, *DirMonData);
        var fs = util.opaqPtrTo(dptr, *EventSource);
        print("'{s}': moved to '{s}'\n", .{fs.info.fs.fname, pd.dir});
        fs.enable(&me.md.eq, .{}) catch unreachable;
    }

    fn workF08(me: *StageMachine, src: ?*StageMachine, dptr: ?*anyopaque) void {
        _ = src;
        var pd = util.opaqPtrTo(me.data, *DirMonData);
        _ = pd;
        var fs = util.opaqPtrTo(dptr, *EventSource);
        print("'{s}': created\n", .{fs.info.fs.fname});
        fs.enable(&me.md.eq, .{}) catch unreachable;
    }

    fn workF09(me: *StageMachine, src: ?*StageMachine, dptr: ?*anyopaque) void {
        _ = src;
        var pd = util.opaqPtrTo(me.data, *DirMonData);
        _ = pd;
        var fs = util.opaqPtrTo(dptr, *EventSource);
        print("'{s}': deleted\n", .{fs.info.fs.fname});
        fs.enable(&me.md.eq, .{}) catch unreachable;
    }

    fn workF10(me: *StageMachine, src: ?*StageMachine, dptr: ?*anyopaque) void {
        _ = src;
        var pd = util.opaqPtrTo(me.data, *DirMonData);
        var fs = util.opaqPtrTo(dptr, *EventSource);
        print("'{s}': deleted\n", .{pd.dir});
        fs.enable(&me.md.eq, .{}) catch unreachable;
    }

    fn workF11(me: *StageMachine, src: ?*StageMachine, dptr: ?*anyopaque) void {
        _ = src;
        var pd = util.opaqPtrTo(me.data, *DirMonData);
        var fs = util.opaqPtrTo(dptr, *EventSource);
        print("'{s}': moved somewhere\n", .{pd.dir});
        fs.enable(&me.md.eq, .{}) catch unreachable;
    }

    // unused
    fn workF12(me: *StageMachine, src: ?*StageMachine, dptr: ?*anyopaque) void {
        _ = me;
        _ = src;
        _ = dptr;
    }

    fn workF13(me: *StageMachine, src: ?*StageMachine, dptr: ?*anyopaque) void {
        _ = src;
        var pd = util.opaqPtrTo(me.data, *DirMonData);
        _ = pd;
        var fs = util.opaqPtrTo(dptr, *EventSource);
        _ = fs;
        print("unmounted\n", .{});
    }

    fn workF14(me: *StageMachine, src: ?*StageMachine, dptr: ?*anyopaque) void {
        _ = src;
        var pd = util.opaqPtrTo(me.data, *DirMonData);
        _ = pd;
        var fs = util.opaqPtrTo(dptr, *EventSource);
        print("event queue overflow occured\n", .{});
        fs.enable(&me.md.eq, .{}) catch unreachable;
    }

    fn workF15(me: *StageMachine, src: ?*StageMachine, dptr: ?*anyopaque) void {
        _ = src;
        var pd = util.opaqPtrTo(me.data, *DirMonData);
        var fs = util.opaqPtrTo(dptr, *EventSource);
        _ = fs;
        print("'{s}': ignored\n", .{pd.dir});
        os.raise(os.SIG.TERM) catch unreachable;
    }

    fn workS0(me: *StageMachine, src: ?*StageMachine, dptr: ?*anyopaque) void {
        _ = src;
        var sg = util.opaqPtrTo(dptr, *EventSource);
        var si = sg.info.sg.sig_info;
        print("got signal #{} from PID {}\n", .{si.signo, si.pid});
        me.msgTo(null, Message.M0, null);
    }

    fn workLeave(me: *StageMachine) void {
        var pd = util.opaqPtrTo(me.data, *DirMonData);
        pd.fs0.disable(&me.md.eq) catch unreachable;
        print("Bye!\n", .{});
    }
};
