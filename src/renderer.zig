// Public API goes here

// Basic API:
// var device = GPUDevice.init(io, allocator);
// device.connectHost(.{ .window = &hostWindow, .context = &hostContext });
//
// const vertexShaderID = try device.loadBinary(.{
//  .key = "myVertexBinary.spv",
//  .filename = "assets/myVertexBinary.spv",
// });
//
// _ = try device.loadFile(.{
//  .key = "myFragmentBinary.spv",
//  .filename = "assets/myFragmentBinary.spv",
//  .type = .binary,
// });
//
// const fragmentShaderID = device.findByKey("myFragmentBinary.spv", .binary).?;
//
// const shaderHandle = try device.linkShader(.{
//  .vertexHandle = vertexShaderID,
//  .fragmentHandle = fragmentShaderID,
//  .key = "ExampleShader",
//  .type = .spv, // maybe not needed
// });
//
//
// const myVertexFormat = try device.buildVertexFormat(.{
//  .key = "DefaultVertexFormat",
//  .attribs = &.{
//     .{ .type = .Float, .len = 2, .name = "position" },
//     .{ .type = .Float, .len = 2, .name = "uv" },
//  },
// });
//
// const pipeline = try device.buildPipeline(.{
//      .key = "defaultPipeline",
//      .shader = shaderHandle,
//      .topology = .triangles,
//      .culling = .none,
//      .vertexFormat = myVertexFormat,
// });
//
// const meshObjSource = try device.loadFile(.{
//  .key = "mesh.obj",
//  .filename = "assets/myMesh.obj",
//  .type = .text,
// });
//
// // uses a default obj vertex format.
// const meshObjHandle = try device.parseMeshData(meshObjSource, .wavefront_obj);
// device.delete(meshObjSource);
//
// const DefaultObjToMyMeshFormatConverter = struct {
//  pub fn convertVertex(srcFmt: *const VertexFormat, dstFmt: *const VertexFormat, source: []const f32, dest: []f32) !void {
//    const srcPositionAttrib = try srcFmt.getAttribByKey("position");
//    const srcUvAttrib = try srcFmt.getAttribByKey("uv");
//
//    const dstPositionAttrib = try dstFmt.getAttribByKey("position");
//    const dstUvAttrib = try dstFmt.getAttribByKey("uv");
//
//    // not perfectly safe but works for the example
//
//    std.debug.assert(dest.len >= dstPositionAttrib.len + dstUvAttrib.len);
//    std.debug.assert(source.len >= srcPositionAttrib.len + srcUvAttrib.len);
//
//    // Probably add VertexFormat.Copy/Convert helpers but for the basic version this should be good enough
//
//    // copy position (source xyz --> dest xy)
//    var sourceCursor: usize = srcPositionAttrib.offset;
//    var destCursor: usize = dstPositionAttrib.offset;
//    dest[destCursor] = source[sourceCursor];
//    dest[destCursor + 1] = source[sourceCursor + 1];
//
//    // copy uv (direct copy)
//    sourceCursor = srcUvAttrib.offset;
//    destCursor = dstUvAttrib.offset;
//    dest[destCursor] = source[sourceCursor];
//    dest[destCursor + 1] = source[sourceCursor + 1];
//  }
//
//  const convertedMeshID = try device.convertMesh(meshObjHandle, DefaultObjToMyMeshFormatConverter, .{ .discard_original = true, .key = .recycle });
//  const uploadedMeshID = try device.requestResourceHandle(.{
//     .key = "uploadedMesh",
//     .type = .mesh,
//  });
//
//  var workBuffer = try device.requestWorkBuffer(.{});
//  workBuffer.record(.beginCopy);
//
//  workBuffer.record(.{ .upload = .{ .source = convertedMeshID, .dest = uploadedMeshID } });
//
//  workBuffer.record(.endCopy);
//  try device.submitCopyPass(workBuffer);
//  workBuffer.clear();
//
//  main_loop(){
//    workBuffer.record(.beginRender);
//    workBuffer.record(.{ .render = .{ .mesh = uploadedMeshID, .instanceData = &instanceData, .instanceLen = @sizeOf(InstanceData) } });
//    workBuffer.record(.endRender);
//    try device.submitRenderPass(pipeline, workBuffer);
//    try device.hostPresent();
//  }
// };

const core = @import("renderer/core.zig");
pub const DummyBackend = @import("renderer/backends/dummy.zig");

pub const Resourcetype = core.ResourceType;
pub const GPUDevice = core.GPUDevice;
