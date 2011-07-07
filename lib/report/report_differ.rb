require 'report/report_parser.rb'
  
  module AnsiHelp
    def ansi(code, text)
      "\033[#{code}m#{text}\033[0m"
    end 
    def noattrs(text);  ansi(0,text);   end
    def bold(text);     ansi(1,text);   end
    def red(text);      ansi(31,text);  end
    def green(text);    ansi(32,text);  end
    def yellow(text);   ansi(33,text);  end
    def white(text);    ansi(37,text);  end
    def redbg(text);    ansi(41,text);  end
    def greenbg(text);  ansi(42,text);  end
  end

class MatchedRequests
  attr_accessor :request1, :request2
  def initialize(request1, request2)
    @request1 = request1
    @request2 = request2
  end

  def key
    r = @request1
    [["%s#%s" % [r.controller, r.action]],  r.verb, r.format].compact.join(".")
  end

  def values_ab(method_name)
    [ @request1, @request2 ].map {|req| req.send(method_name) }
  end

  def to_s
    "%s matches %s" %[@request1, @request2]
  end
end
class UnmatchedRequest
  attr_accessor :report, :request
  def initialize(report, request)
    @report = report
    @request = request
  end
  def to_s
    "%s only in report %s" %[@request, @report.name]
  end
end

class ReportDiffer
  include AnsiHelp

  def banner(title)
    ("="*30) + title + ("=" * 30) + "\n"
  end

  def compute_difference_in_values(va, vb)
    return 1 if va==vb
    sign= (vb > va) ? 1 : -1
    return sign * 999999 if (va==0 || vb==0)
    min=[va,vb].min
    max=[va,vb].max
    abs=max/min.to_f
    abs=("%.2f"%abs).to_f
    return sign * abs
  end

  def compute_difference(a, b, method_name)
      va= a.send(method_name)
      vb= b.send(method_name)
      return compute_difference_in_values(va,vb)
  end

  def find_matched_actions(ra, rb)
    matched=[]
    ra.requests.each do |req_a|
      req_b = rb.get_request_like(req_a)
      unless req_b.nil?
        matched << MatchedRequests.new(req_a, req_b) 
      end
    end
    matched
  end

  def find_unmatched_actions(ra, rb)
    unmatched=[]
    [[ra, rb], [rb, ra]].each do|a,b|
      a.requests.each do |req_a|
        req_b = b.get_request_like(req_a)
        if req_b.nil?
          (unmatched << UnmatchedRequest.new(a, req_a)) 
        end
      end
    end
    unmatched
  end

  def compare_attribs(holder_a, holder_b, attribs_for_comparison)
    results = {}
    attribs_for_comparison.each do |method_name|
      change = compute_difference(holder_a, holder_b, method_name)
      diff_hash = {}
      diff_hash[:change] = change 
      diff_hash[:from] = holder_a.send(method_name)
      diff_hash[:to] = holder_b.send(method_name)
      results["diff_#{method_name}".to_sym] = diff_hash 
    end
    return results
  end

  def compare_matched_action(matched_action, threshold)
    attribs=[:count, :avg_time, :std_dev, :max_time, :min_time]
    return compare_attribs(matched_action.request1, matched_action.request2, attribs)
  end

  def compare_summaries(report_a, report_b, threshold=1.3)
    attribs=[:count, :avg_time, :std_dev, :max_time, :min_time]
    return compare_attribs(report_a.summary, report_b.summary, attribs)
  end

  def compare_requests(report_a, report_b, threshold)
    diffs = {}
    matched_actions = find_matched_actions(report_a, report_b)
    matched_actions.each do |matched_action|
      diffs[matched_action.key] = compare_matched_action(matched_action, threshold)
    end
    diffs
  end

  def compare(report_a, report_b, threshold=1)
    summary_diff=compare_summaries(report_a, report_b, threshold)
    req_diffs=compare_requests(report_a, report_b, threshold)
    {:threshold => threshold, :summary_diff => summary_diff, :request_diffs => req_diffs, :unmatched_actions => find_unmatched_actions(report_a, report_b)}
  end

  def should_use_ansi()
   false
  end

  def prepare_report_line_for_request(title, diff_hash, threshold)
    text=""
    text << "%-50s" % title
    rd = diff_hash
    w = 20
    cell_texts = []
    %w(count avg_time std_dev min_time max_time).each do |metric|
      metric_key = ("diff_"+metric).to_sym
      diff = rd[metric_key]
      change = diff[:change]
      from = diff[:from]
      to = diff[:to]
      sign = (change == 1 ? " " : (change > 0 ? "+":""))
      change_text="%s%.1f" % [ sign, change ]
      if should_use_ansi()
        change_text = bold(change_text)
        change_text = change > 0 ? redbg(change_text) : ( change.abs > 2 ? greenbg(change_text) : green(change_text) )
      end
      cell_text = ( "%s(%s->%s)" % [ change_text, from, to])
      if change.abs < threshold
        marker = should_use_ansi() ? noattrs(white("~")) : "~"  #when using ansi pad the marker with the same number of ansi control chars as the other columns get
        cell_text = "%-#{w}s" % marker 
      end
      cell_texts << cell_text
    end
    #max_width = cell_texts.map{|ct| ct.length}.max
   ## w=max_width+3
    text << (" %-#{w}s %-#{w}s %-#{w}s %-#{w}s %-#{w}s\n" % cell_texts)
  end

  def prepare_report_line_for_unmatched_action(ac)
    "%-60s only in %s\n" % [ ac.request, ac.report ]
  end

  def prepare_report(diff_data)
    dd=diff_data
    threshold = dd[:threshold]
    text =""
    text << "#Threshold=#{threshold}\n"
    w=20
    
    #Headers 
    text << "%-50s %-#{w}s %-#{w}s %-#{w}s %-#{w}s %-#{w}s\n" % ["Request_Times_Summary:", "Count", "Avg", "Std_Dev", "Min", "Max"]
    
    #Summary - all requests - line
    text << prepare_report_line_for_request("ALL_REQUESTS", dd[:summary_diff], threshold)
    text << "\n"
    #Go through all the request diffs and print them, in order of frequency
    req_diffs = dd[:request_diffs]
    req_diffs.sort_by{|k,v| v[:diff_count][:from]}.reverse.each do |req_key, req_diff|
      text << prepare_report_line_for_request(req_key, req_diff, threshold)
    end

    text << "\nUnmatched_Actions: \n\n"
    dd[:unmatched_actions].each do |unmatched_action|
      text << prepare_report_line_for_unmatched_action(unmatched_action)
    end
    text
  end

  def self.compare_files(report_file_a, report_file_b)  
    differ = ReportDiffer.new
    parser = ReportParser.new
    reports = [report_file_a, report_file_b].map do |filename|
      text=File.read(filename)
      report = parser.parse(File.basename(filename), text)
      report
    end
    diff_data = differ.compare(reports[0], reports[1])
    puts differ.prepare_report(diff_data)
  end

end

if __FILE__ == $0
  abort("usage #{File.dirname(__FILE__)} report_a report_b") if ARGV.size!=2
  ReportDiffer.compare_files(ARGV[0], ARGV[1])  
end

