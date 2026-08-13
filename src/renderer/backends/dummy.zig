const interface = @import("../interface.zig");

pub const Context = struct{};
pub const Config = struct{};
const MaxAlign = interface.Backend.MaxAlign;
const Pipeline = interface.Pipeline;
const PipelineConfig = interface.PipelineConfig;
const Texture = interface.Texture;
const TextureConfig = interface.TextureConfig;
const Buffer = interface.Buffer;
const CopyCommandBuffer = interface.CopyCommandBuffer;
const RenderCommandBuffer = interface.RenderCommandBuffer;
const BufferHint = interface.BufferHint;


pub fn backend() interface.Backend {
    return .{
        .init = init,
        .deinit = deinit,
        .allocateBuffer = allocateBuffer,
        .freeBuffer = freeBuffer,
        .mapBuffer = mapBuffer,
        .unmapBuffer = unmapBuffer,
        .createPipeline = createPipeline,
        .destroyPipeline = destroyPipeline,
        .textureData = textureData,
        .createTexture = createTexture,
        .destroyTexture = destroyTexture,
        .submitRenderWork = submitRenderWork,
        .submitCopyWork = submitCopyWork,
    };
}

pub fn init (_: Config) Context { return .{}; } // TODO rework context and config
pub fn deinit (_: Context) void{}

pub fn allocateBuffer (_: Context, _: usize, _: BufferHint) ?Buffer { return null; }
pub fn freeBuffer (_: Context, _: Buffer) void {}
pub fn mapBuffer (_: Context, _: Buffer) ?[]align(MaxAlign) u8 { return null; }
pub fn unmapBuffer (_: Context, _: Buffer, _: []align(MaxAlign) u8) void {}

pub fn createPipeline (_: Context, _: PipelineConfig) ?Pipeline { return null; }
pub fn destroyPipeline (_: Context, _: Pipeline) void {}

pub fn createTexture (_: Context, _: TextureConfig) ?Texture { return null; }
pub fn destroyTexture (_: Context, _: Texture) void {}

/// for when you need to attach or re-upload texture data, for most cases you should just
/// attach an already uploaded pixel buffer through the creation. This only works when
/// texture compatibility is maintained (width,height,format,etc)
pub fn textureData (_: Context, _: Texture, _: Buffer) void {}

pub fn submitRenderWork (_: Context, _: *RenderCommandBuffer) anyerror!void {}
pub fn submitCopyWork (_: Context, _: *CopyCommandBuffer) anyerror!void {}
