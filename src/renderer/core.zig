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

pub fn GPUDevice(comptime backend: interface.Backend) type {
    return struct {
        const This = @This();

        io: std.Io,
        allocator: std.mem.Allocator,

        binaries: Repository([]const u8),
        strings: Repository([]const u8),
        pipelines: Repository(interface.Pipelines),
        buffers: Repository(interface.Buffer),

        lookup: std.AutoHashMap([]const u8, Handle),
        context: backend.Context,

        pub fn init(conf: backend.Config, io: std.Io, allocator: std.mem.Allocator) This {
            const context = backend.init(conf);
            errdefer backend.deinit(context);

            return .{
                .io = io,
                .allocator = allocator,
                .binaries = .init(allocator),
                .strings = .init(allocator),
                .pipelines = .init(allocator),
                .buffers = .init(allocator),
                .lookup = .init(allocator),
                .context = context,
            };
        }

        pub fn deinit(this: *This) void {
            this.binaries.deinit();
            this.strings.deinit();
            this.pipelines.deinit();
            this.buffers.deinit();

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
            }

            return externHandle;
        }

        pub const Handle = struct {
            handle: Repository(void).Handle,
            resType: ResourceType,
        };
    };
}
