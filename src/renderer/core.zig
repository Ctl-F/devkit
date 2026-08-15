const sdl = @cImport(@cInclude("SDL3/SDL.h"));
const std = @import("std");
const interface = @import("interface.zig");

const Repository = @import("repository.zig").Repository;

pub const ResourceType = enum(u32) {
    Binary,
    Text,
    Mesh,
    VertexFormat,
    Shader,
    Texture,
    Pipeline,
};

pub fn GPUDevice(comptime backend: type) type {
    return struct {
        const This = @This();

        pub const WorkAdapter = fn(comptime ContextT: type, context: ContextT, work: *interface.RenderCommandBuffer) !void;

        io: std.Io,
        allocator: std.mem.Allocator,

        binaries: Repository([]const u8),
        strings: Repository([]const u8),
        pipelines: Repository(interface.Pipeline),
        buffers: Repository(interface.Buffer),

        lookup: std.AutoHashMap([]const u8, Handle),
        backup: std.AutoHashMap(Handle, []const u8),
        context: backend.Context,

        pub fn init(conf: backend.Config, io: std.Io, allocator: std.mem.Allocator) !This {
            const context = try backend.init(conf);
            errdefer backend.deinit(context);

            return .{
                .io = io,
                .allocator = allocator,
                .binaries = .init(allocator),
                .strings = .init(allocator),
                .pipelines = .init(allocator),
                .buffers = .init(allocator),
                .lookup = .init(allocator),
                .backup = .init(allocator),
                .context = context,
            };
        }

        pub fn deinit(this: *This) void {
            this.binaries.deinit();
            this.strings.deinit();
            this.pipelines.deinit();
            this.buffers.deinit();

            this.backup.deinit();
            this.lookup.deinit();
            backend.deinit(this.context);
        }

        pub const FileResource = struct {
            filename: []const u8,
            type: enum { binary, text },
            key: []const u8,
        };

        pub fn loadFile(this: *This, resource: FileResource) !Handle {
            const data = try std.Io.Dir.cwd().readFileAlloc(this.io, resource.filename, this.allocator, .unlimited);
            errdefer this.allocator.free(data);

            const handle, const htype = if (resource.type == .binary) blk: {
                const h = try this.binaries.add(data);
                break :blk .{ h, ResourceType.Binary };
            } else blk2: {
                const h = try this.strings.add(data);
                break :blk2 .{ h, ResourceType.Text };
            };

            errdefer {
                (if (resource.type == .binary) this.binaries else this.strings).erase(handle);
            }

            const externHandle = Handle{
                .handle = handle,
                .resType = htype,
            };

            if (resource.key.len > 0) {
                try this.lookup.put(resource.key, externHandle);
                errdefer this.lookup.remove(resource.key);

                try this.backup.put(externHandle, resource.key);
                errdefer this.backup.remove(externHandle);
            }

            return externHandle;
        }

        pub fn delete(this: *This, handle: Handle) void {
            if(this.backup.get(handle)) |key| {
                this.lookup.remove(key);
                this.backup.remove(handle);
            }

            std.debug.assert(handle.isValid(this));

            switch(handle.resType){
                .Binary => this.deleteBinary(handle),
                .Text => this.deleteText(handle),
                .Pipeline => this.destroyPipeline(handle),
                .Buffer => this.destroyBuffer(handle),
                else => unreachable,
            }
        }

        fn deleteBinary(this: *This, handle: Handle) void {
            const data = this.binaries.get(handle.handle) orelse unreachable;
            this.allocator.free(data);

            this.binaries.erase(handle.handle);
        }

        fn deleteText(this: *This, handle: Handle) void {
            const data = this.strings.get(handle.handle) orelse unreachable;
            this.allocator.free(data);
            this.strings.erase(handle.handle);
        }

        pub const BufferResource = struct {
            key: []const u8,
            length: usize,
            usage: interface.BufferHint,
        };

        pub fn createBuffer(this: *This, bufferConfig: BufferResource) !Handle {
            const buffer = backend.allocateBuffer(this.context, bufferConfig.length, bufferConfig.usage);
            if(buffer == null) {
                return error.UnableToAllocateBuffer;
            }
            errdefer backend.freeBuffer(this.context, buffer.?);

            const h = try this.buffers.add(buffer.?);
            errdefer this.buffers.delete(h);

            const handle = Handle{
                .handle = h,
                .resType = .Buffer,
            };

            if(bufferConfig.key.len > 0){
                try this.lookup.put(bufferConfig.key, handle);
                errdefer this.lookup.remove(bufferConfig.key);

                try this.backup.put(handle, bufferConfig.key);
                errdefer this.backup.remove(handle);
            }

            return handle;
        }

        fn destroyBuffer(this: *This, buffer: Handle) void {
            std.debug.assert(buffer.resType == .Buffer);

            const nativeBuffer = this.buffers.get(buffer.handle) orelse unreachable;
            backend.freeBuffer(nativeBuffer);

            this.buffers.delete(buffer.handle);
        }

        pub fn createPipeline(this: *This, config: interface.PipelineConfig) !Handle {
            const pipeline = backend.createPipeline(this.context, config);

            if(pipeline == null){
                return error.InvalidPipelineConfiguration;
            }
            errdefer backend.destroyPipeline(this.context, pipeline.?);

            const h = try this.pipelines.add(pipeline);
            errdefer this.pipelines.delete(h);


            const handle = Handle{
                .handle = h,
                .resType = .Pipeline,
            };

            if(config.name.len > 0){
                try this.lookup.put(config.name, handle);
                errdefer this.lookup.remove(config.name);

                try this.backup.put(handle, config.name);
                errdefer this.backup.remove(handle);
            }

            return handle;
        }

        fn destroyPipeline(this: *This, pipelineHandle: Handle) void {
            std.debug.assert(pipelineHandle.resType == .Pipeline);

            const nativePipeline = this.pipelines.get(pipelineHandle.handle) orelse unreachable;
            backend.destroyPipeline(this.context, nativePipeline);

            this.pipelines.delete(pipelineHandle.handle);
        }

        pub fn submitRenderWork(this: *This,
            work: *interface.RenderCommandBuffer,
            comptime adapters: []WorkAdapter,
            comptime contexts: []anytype) !void {

            comptime {
                std.debug.assert(adapters.len == contexts.len);
            }

            inline for(adapters, 0..) |adapter, index| {
                try adapter(@TypeOf(contexts[index]), contexts[index], work);
            }

            this.normalize(work);
            try backend.submitRenderWork(this.context, work);
        }

        fn normalize(this: *This, work: *interface.RenderCommandBuffer) void {
            _ = this;
            _ = work;
        }

        pub const Handle = struct {
            handle: Repository(void).Handle,
            resType: ResourceType,

            pub fn isValid(this: @This(), parent: *This) bool {
                return switch(this.resType){
                    .Binary => parent.binaries.get(this.handle) != null,
                    .Text => parent.strings.get(this.handle) != null,
                    .Pipeline => parent.pipelines.get(this.handle) != null,
                    .Buffer => parent.buffers.get(this.handle) != null,
                    else => unreachable,
                };
            }
        };
    };
}
