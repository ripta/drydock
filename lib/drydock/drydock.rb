
module Drydock

  def self.build(opts = {}, &blk)
    Project.new(opts).tap do |project|
      dryfile, dryfilename = yield
      begin
        project.instance_eval(dryfile, dryfilename)
      ensure
        project.finalize!
      end
    end
  end

  def self.from(repo, opts = {}, &blk)
    opts = opts.clone
    tag  = opts.delete(:tag, 'latest')

    build(opts).tap do |project|
      project.from(repo, tag)
      yield project
    end
  end

  def self.using(project)
    raise NotImplementedError, "TODO(rpasay)"
  end

end
