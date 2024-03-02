const std = @import("std");

pub fn main() !void {
    var server = std.net.StreamServer.init(.{});
    defer server.deinit();

    const addr = try std.net.Address.resolveIp("0.0.0.0", 8080);
    try server.listen(addr);
    defer server.close();

    while (server.accept()) |conn| {
        try handle_connection(conn);
    } else |err| {
        return err;
    }
}

fn handle_connection(conn: std.net.StreamServer.Connection) !void {
    defer conn.stream.close();

    var buffer: [1024]u8 = .{};
    const request_size = try conn.stream.read(&buffer);
    const request = buffer[0..request_size];

    const eol = std.mem.indexOf(u8, request, "\r\n") orelse unreachable;
    const first_line = request[0..eol];

    var parts = std.mem.split(u8, first_line, " ");

    const method = parts.next() orelse unreachable;
    const path = parts.next() orelse unreachable;

    std.log.debug("Req: {s} {s}", .{ method, path });

    if (std.mem.eql(u8, path, "/foo")) {
        try getFoo(conn);
    } else if (std.mem.eql(u8, path, "/bar")) {
        try getBar(conn);
    } else {
        _ = try conn.stream.write("HTTP/1.1 404 Not Found\r\n\r\naaa");
    }
}

fn getFoo(conn: std.net.StreamServer.Connection) !void {
    _ = try conn.stream.write("HTTP/1.1 200 OK\r\n\r\nFoo!");
}

fn getBar(conn: std.net.StreamServer.Connection) !void {
    _ = try conn.stream.write("HTTP/1.1 200 OK\r\n\r\nBar!");
}
