const std = @import("std");

const Self = @This();

pub const Face = struct {
    positions: [3]u32,
    normals: ?[3]u32,
    uvs: ?[3]u32,
};

positions: [][3]f32,
normals: [][3]f32,
uvs: [][2]f32,
faces: []Face,

pub fn load(reader: anytype, allocator: std.mem.Allocator) !Self {
    var line_buffer = std.ArrayList(u8).init(allocator);
    defer line_buffer.deinit();

    var positions = std.ArrayList([3]f32).init(allocator);
    errdefer positions.deinit();

    var normals = std.ArrayList([3]f32).init(allocator);
    errdefer normals.deinit();

    var uvs = std.ArrayList([2]f32).init(allocator);
    errdefer uvs.deinit();

    var faces = std.ArrayList(Face).init(allocator);
    errdefer faces.deinit();

    while (true) {
        reader.readUntilDelimiterArrayList(&line_buffer, '\n', std.math.maxInt(usize)) catch |err| switch (err) {
            error.EndOfStream => break,
            else => |e| return e,
        };

        // Empty lines
        if (line_buffer.items.len == 0) continue;

        var it = std.mem.split(u8, line_buffer.items, " ");
        const first = it.next().?;

        // TODO: Support multiple objects
        // TODO: Support materials

        // Vertex positions
        if (std.mem.eql(u8, first, "v")) {
            const v0 = try std.fmt.parseFloat(f32, it.next() orelse return error.UnknownEndOfLine);
            const v1 = try std.fmt.parseFloat(f32, it.next() orelse return error.UnknownEndOfLine);
            const v2 = try std.fmt.parseFloat(f32, it.next() orelse return error.UnknownEndOfLine);
            try positions.append([_]f32{ v0, v1, v2 });
            continue;
        }

        // Vertex normals
        if (std.mem.eql(u8, first, "vn")) {
            const n0 = try std.fmt.parseFloat(f32, it.next() orelse return error.UnknownEndOfLine);
            const n1 = try std.fmt.parseFloat(f32, it.next() orelse return error.UnknownEndOfLine);
            const n2 = try std.fmt.parseFloat(f32, it.next() orelse return error.UnknownEndOfLine);
            try normals.append([_]f32{ n0, n1, n2 });
            continue;
        }

        // Vertex UVs
        if (std.mem.eql(u8, first, "vt")) {
            const uv0 = try std.fmt.parseFloat(f32, it.next() orelse return error.UnknownEndOfLine);
            const uv1 = try std.fmt.parseFloat(f32, it.next() orelse return error.UnknownEndOfLine);
            try uvs.append([_]f32{ uv0, uv1 });
            continue;
        }

        // Faces
        if (std.mem.eql(u8, first, "f")) {
            var face = Face{
                .positions = [_]u32{ 0, 0, 0 },
                .uvs = [_]u32{ 0, 0, 0 },
                .normals = [_]u32{ 0, 0, 0 },
            };
            inline for (0..3) |i| {
                const slice = it.next() orelse return error.UnknownEndOfLine;
                var v_u_n = std.mem.split(u8, slice, "/");

                // Position
                face.positions[i] = try std.fmt.parseUnsigned(u32, v_u_n.next() orelse return error.UnknownEndOfLine, 10) - 1;

                // UV
                const u_slice = v_u_n.next() orelse return error.UnknownEndOfLine;
                if (u_slice.len != 0 and face.uvs != null) {
                    face.uvs.?[i] = try std.fmt.parseUnsigned(u32, u_slice, 10) - 1;
                } else {
                    face.uvs = null;
                }

                // Normal
                const n_slice = v_u_n.next() orelse return error.UnknownEndOfLine;
                if (n_slice.len != 0 and face.normals != null) {
                    face.normals.?[i] = try std.fmt.parseUnsigned(u32, n_slice, 10) - 1;
                } else {
                    face.normals = null;
                }
            }
            try faces.append(face);
            continue;
        }
    }

    return .{
        .positions = try positions.toOwnedSlice(),
        .normals = try normals.toOwnedSlice(),
        .uvs = try uvs.toOwnedSlice(),
        .faces = try faces.toOwnedSlice(),
    };
}

pub fn deinit(self: *const Self, allocator: std.mem.Allocator) void {
    allocator.free(self.positions);
    allocator.free(self.uvs);
    allocator.free(self.normals);
    allocator.free(self.faces);
}
