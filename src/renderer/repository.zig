const std = @import("std");

pub fn Repository(Asset: type) type {
    return struct {
        pub const Handle = u32;
        const Index = u32;

        allocator: std.mem.Allocator,
        backing: std.ArrayList(Asset),
        backingMap: std.ArrayList(Index),
        sparse: std.ArrayList(?Index),

        pub fn init(allocator: std.mem.Allocator) @This() {
            return .{
                .allocator = allocator,
                .backing = .empty,
                .backingMap = .empty,
                .sparse = .empty,
            };
        }

        pub fn deinit(this: *@This()) void {
            this.backing.deinit(this.allocator);
            this.backingMap.deinit(this.allocator);
            this.sparse.deinit(this.allocator);
        }

        pub fn get(this: *@This(), handle: Handle) ?*Asset {
            std.debug.assert(handle < this.sparse.items.len);

            const denseIndex = this.sparse.items[handle] orelse return null;
            return &this.backing.items[denseIndex];
        }

        pub fn add(this: *@This(), asset: Asset) !Handle {
            const backingIndex: u32 = @truncate(this.backing.items.len);

            try this.backing.append(this.allocator, asset);
            errdefer _ = this.backing.pop();

            const idx = blk: {
                for (0..this.sparse.items.len) |idx| {
                    if (this.sparse.items[idx] == null) {
                        this.sparse.items[idx] = backingIndex;
                        errdefer this.sparse.items[idx] = null;
                        break :blk idx;
                    }
                }

                try this.sparse.append(this.allocator, backingIndex);
                errdefer _ = this.sparse.pop();
                break :blk this.sparse.items.len - 1;
            };

            try this.backingMap.append(this.allocator, idx);
            return idx;
        }

        fn eraseNoKey(this: *@This(), handle: Handle) void {
            if (this.backing.items.len == 0) return;

            std.debug.assert(handle < this.sparse.items.len);
            std.debug.assert(this.backing.items.len == this.backingMap.items.len);

            const denseIndex = this.sparse.items[handle] orelse return;
            const lastIndex = this.backing.items.len - 1;

            if (denseIndex == lastIndex) {
                _ = this.backing.pop();
                _ = this.backingMap.pop();
                this.sparse.items[handle] = null;
                return;
            }

            // swap end of list for list[denseIndex];
            const sparseEntryToUpdate = this.backingMap[lastIndex];

            std.mem.swap(Asset, &this.backing.items[denseIndex], &this.backing.items[lastIndex]);
            std.mem.swap(usize, &this.backingMap.items[denseIndex], &this.backingMap.items[lastIndex]);

            _ = this.backing.pop();
            _ = this.backingMap.pop();

            this.sparse.items[handle] = null;
            this.sparse.items[sparseEntryToUpdate] = denseIndex;
        }

        pub fn erase(this: *@This(), assetId: Handle) void {
            this.eraseNoKey(assetId);
        }
    };
}
