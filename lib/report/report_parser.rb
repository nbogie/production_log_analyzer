class Report
  attr_accessor :name
  attr_accessor :requests
  attr_accessor :started_at
  attr_accessor :summary
  
  def initialize
    @summary = Request.new #blagging it.  doesn't have controller/action.
    @requests=[]
  end
  
  def get_request_like(other)
    @requests.select { |r| r.controller == other.controller && r.action == other.action && r.verb==other.verb && r.format==other.format}.first
  end
 def to_s
   @name
 end
end

class Request
  attr_accessor :controller
  attr_accessor :action
  attr_accessor :verb
  attr_accessor :format
  attr_accessor :count, :avg_time, :std_dev, :min_time, :max_time
  def initialize
  end

  def self.create(controller, action, count, avg_time, std_dev, min_time, max_time, options={})
    r = Request.new
    r.verb = options[:verb]
    r.format = options[:format]
    r.controller=controller
    r.action=action
    r.count=count
    r.avg_time=avg_time
    r.std_dev=std_dev
    r.min_time=min_time
    r.max_time=max_time
    return r
  end

  def fixup_controller_name!
    if @controller =~ /^Api([^:].*)Controller/
      @controller = "Api::V1::#{$1}Controller"
    end
  end

  def to_s
    "%s#%s.%s.%s" % [ controller, action, verb, format ]
  end

end

class ReportParser
  def parse(report_name, content)
    report = Report.new
    report.name=report_name
    #TODO: parse report name as a time
    report.started_at=report_name#Time.parse(report_name)
    #ALL REQUESTS:                                   11830   0.085   0.052   0.001   1.053
    content =~ /ALL REQUESTS:\s*([0-9]+)\s+([0-9\.]+)\s+([0-9\.]+)\s+([0-9\.]+)\s+([0-9\.]+)/
    report.summary.count=Integer($1)
    report.summary.avg_time=Float($2)
    report.summary.std_dev=Float($3)
    report.summary.min_time=Float($4)
    report.summary.max_time=Float($5)

    content =~ /\nALL REQUESTS:.*?\n\n(.*)\n\nSlowest Request Times/m
    
    request_lines_block = $1
    throw "No requests found" if request_lines_block.nil?
    request_lines_block.split(/\n/).each_with_index do |line, i|
      request = parse_request(line)
      request.fixup_controller_name!
      if request.nil? || request.controller.nil?
        puts "WARN: unparseable request line: #{line}, index #{i}"
        next
      end
      report.requests << request
    end
    return report
  end
  
  def parse_request(request_line)
    r = Request.new
    #Examples:
    #FooController#update.PUT.xml:         3557    0.144   0.037   0.059   0.712
    #FooController#show.GET:               11707   0.107   0.063   0.015   1.075
    request_line =~ /([a-zA-Z0-9:]+)#([^\.: ]+)\.?([a-zA-Z]+)?\.?([a-zA-Z]+)?:\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)/
    r.controller = $1
    r.action = $2
    r.verb = $3.upcase unless $3.nil?
    r.format = $4.downcase unless $4.nil?
    r.count = $5.to_i
    r.avg_time = $6.to_f
    r.std_dev = $7.to_f
    r.min_time = $8.to_f
    r.max_time = $9.to_f
    r
  end
  
  def looks_ok_on_quick_peek?(content)
    return false if content.nil? || content.empty? 
    return false if (content =~ /No requests to analyze/)
    return true
  end

end
