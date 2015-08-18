
module Docker
  class Container
    def archive_get(path = '/', &blk)
      query = { 'path' => path }
      connection.get(path_for(:archive), query, response_block: blk)
      self
    end

    def archive_put(path = '/', overwrite: false, &blk)
      headers = { 'Content-Type' => 'application/x-tar' }
      query   = { 'path' => path, 'noOverwriteDirNonDir' => overwrite }

      output = StringIO.new
      blk.call(output)
      output.rewind

      connection.put(path_for(:archive), query, headers: headers, body: output)
      self
    end
  end
end
