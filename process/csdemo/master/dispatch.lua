function slave2master:test(conn, num, str, tbl)
	core.debug(1, num, str)

	PrintTable(tbl, 1)

	master2slave:test(conn, {msg = "test rpc before ack"})
end
