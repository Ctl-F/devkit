const std = @import("std");

pub const Topology = enum(u8) {
    Triangles,
    TriangleList,
    TriangleStrip,
    Lines,
    LineList,
    Points,
};

pub const CullMode = enum(u8) {
    None,
    BackFace,
    FrontFace,
};

pub const WindingOrder = enum(u8) {
    Clockwise,
    CounterClockwise,
};

pub const Blending = enum(u8) {
    None,
    Alpha,
    Add,
    Multiply,
    Subtract,
};

pub const VertexType = enum(u8) {
    Float,
};

pub const VertexLength = enum(u8) {
    One = 1,
    Two = 2,
    Three = 3,
    Four = 4,
};

pub const VertexAttribute = struct {
    type: VertexType,
    length: VertexLength,
    offset: ?u32 = null,
};

pub const Resources = struct {
    Textures: u32,
    Samplers: u32,
    StorageBuffers: u32,
    UniformBuffers: u32,
};

pub const ShaderStage = enum(u8) {
    Vertex = 0,
    Fragment = 1,
};

pub const ShaderSource = enum(u8) {
    glsl,
    spv,
};

pub const ShaderStageInfo = struct {
    stage: ShaderStage,
    blob: []const u8,
    resources: Resources,
    shaderSource: ShaderSource,
};

pub const ShaderInfo = struct {
    name: []const u8,
    vertex: ShaderStageInfo,
    fragment: ShaderStageInfo,
};

pub const PipelineConfig = struct {
    name: []const u8,
    topology: Topology,
    culling: CullMode,
    winding: WindingOrder,
    blending: Blending,
    vertexFormat: []const VertexAttribute,
    resources: Resources,
    depth: bool,
    shaderInfo: ShaderInfo,
};

/// BufferUsage/BufferVisibility/BufferHint
/// are buffer - hints - to the backend. They may or may not be
/// fully respected and some of them might boil down to the same
/// internal buffer kinds. They act as hints as to what semantically the
/// bufer will be used for and are not literal configuration specifications
/// like many of the other configuration options
pub const BufferUsage = enum(u8) {
    vertex,
    index,
    storage,
    uniform,
    instance,
    pixels,
    generic,
};

pub const BufferVisibility = enum(u8) {
    cpu = 1,
    gpu = 2,
    both = 3,

    pub inline fn cpuVisible(this: @This()) bool {
        return (@as(u8, @intFromEnum(this)) & @as(u8, @intFromEnum(BufferVisibility.cpu))) != 0;
    }
    pub inline fn gpuVisible(this: @This()) bool {
        return (@as(u8, @intFromEnum(this)) & @as(u8, @intFromEnum(BufferVisibility.gpu))) != 0;
    }

    pub inline fn transferSuitable(this: @This()) bool {
        return this.cpuVisible() and this.gpuVisible();
    }
};

/// the defaults here are the most applicable to the widest number of situations
/// THEY ARE NOT THE MOST PERFORMANT IN NEARLY ANY SITUATION AND SHOULD NOT BE USED
/// UNLESS THIS IS TRULY THE ONLY COMBINATION THAT MAKES SENSE
pub const BufferHint = struct {
    usage: BufferUsage = .generic,
    visibility: BufferVisibility = .both,
};

pub const TextureFormat = enum(u8) {
    rgba32 = 0,
    bgra32 = 1,
};

pub const SampleFilter = enum(u8) {
    Linear,
    Nearest,
};

pub const EdgePolicy = enum(u8) {
    Clamp,
    Repeat,
    RepeatMirrored,
};

pub const SamplerInfo = struct {
    minFilter: SampleFilter,
    magFilter: SampleFilter,
    edgePolicy: EdgePolicy,
};

pub const TextureConfig = struct {
    name: []const u8,
    width: u32,
    height: u32,
    format: TextureFormat,
    data: ?Buffer,
    mipLevels: u8,
    samplerInfo: SamplerInfo,
};

pub const RenderCommand = union(enum) {
    renderBegin: Pipeline,
    renderEnd,

    render: Render,
    renderInstanced: RenderInstanced,

    pub const Render = struct {};
    pub const RenderInstanced = struct {};
};

pub const CopyCommand = union(enum) {
    copyBegin,
    copyEnd,
    copy: Copy,
    pub const Copy = struct {};
};

pub const RenderCommandBuffer = struct {
    commands: std.ArrayList(RenderCommand),

    pub const empty: @This() = .{ .commands = .empty };

    pub fn begin(allocator: std.mem.Allocator, pipeline: Pipeline) @This() {
        var new = @This().empty;

        try new.commands.append(allocator, .{
            .renderBegin = pipeline,
        });

        return new;
    }


    pub fn render()
};

pub const CopyCommandBuffer = struct {
    commands: std.ArrayList(CopyCommand),
};

pub const Pipeline = *opaque {};
pub const Texture = *opaque {};
pub const Buffer = *opaque {};

pub const Backend = struct {
    pub const Context = *opaque {};
    pub const Config = *opaque {};

    pub const MaxAlign = @alignOf(std.c.max_align_t);

    init: fn (config: Config) anyerror!Context,
    deinit: fn (context: Context) void,

    allocateBuffer: fn (context: Context, length: usize, usage: BufferHint) ?Buffer,
    freeBuffer: fn (context: Context, buffer: Buffer) void,
    mapBuffer: fn (context: Context, buffer: Buffer) ?[]align(MaxAlign) u8,
    unmapBuffer: fn (context: Context, buffer: Buffer, pointer: []align(MaxAlign) u8) void,

    createPipeline: fn (context: Context, config: PipelineConfig) ?Pipeline,
    destroyPipeline: fn (context: Context, pipeline: Pipeline) void,

    createTexture: fn (context: Context, config: TextureConfig) ?Texture,
    destroyTexture: fn (context: Context, texture: Texture) void,

    /// for when you need to attach or re-upload texture data, for most cases you should just
    /// attach an already uploaded pixel buffer through the creation. This only works when
    /// texture compatibility is maintained (width,height,format,etc)
    textureData: fn (context: Context, texture: Texture, buffer: Buffer) void,

    submitRenderWork: fn (context: Context, work: *RenderCommandBuffer) anyerror!void,
    submitCopyWork: fn (context: Context, work: *CopyCommandBuffer) anyerror!void,
};
