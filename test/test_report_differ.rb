#!/usr/bin/env ruby

require 'test/unit'

require 'report/report_parser'
require 'report/report_differ'

class TestReportDiffer < Test::Unit::TestCase

  def file_data(filename)
    'test/example_data/' + filename
  end

  def setup
    @differ = ReportDiffer.new
    report_filenames = ['report_a', 'report_b'].map do |keyname|
      "test/example_data/#{keyname}.txt"
    end
    create_reports()
    #ReportDiffer.compare_files(report_filenames[0], report_filenames[1])
  end


  def test_initialization
    differ = ReportDiffer.new
  end
  
  def test_compute_difference_in_values()
    data = [
      #when increasing
      [100, 1000, 10], 
      [100, 200, 2], 
      [100, 130, 1.3], 
      #when same
      [100, 100, 1], 
      [0,0, 1], 
      #when lessening
      [100, 90, -1.11], 
      [100, 50, -2], 
      [100, 10, -10], 
      #when one number is zero - not sure what we should return here.
      [0.00, 1, 999999], 
      [1, 0.00, -999999], 
    ]
    data.each do |group|
      va, vb, expected = group
      actual = @differ.compute_difference_in_values(va, vb)
      assert_equal(expected, actual, "for #{va}->#{vb}")
    end
  end


  def test_compare
    threshold = 1.2
    actual=@differ.compare(@report_a, @report_b, threshold)
    assert_not_nil actual
    expected = {
      :summary_diff=>
      {
       :diff_count=>{:change => -1.11, :from => 100, :to => 90},
       :diff_avg_time=>{:change => 1.5, :from => 10, :to => 15},
       :diff_min_time=>{:change => 1, :from => 0.1, :to => 0.1},
       :diff_max_time=>{:change => 2.0, :from => 20.0, :to => 40.0},
       :diff_std_dev=>{:change => 3.0, :from => 2.0, :to => 6.0}},
      :request_diffs=>
      {"MyCon#MyAc.get.xml"=>
        { 
          :diff_count=>{:change => 1.1, :from => 100, :to => 110},
          :diff_avg_time=>{:change => 1.2, :from => 100, :to => 120},
          :diff_std_dev=>{:change => 1.3, :from => 100, :to => 130},
          :diff_min_time=>{:change => 1.4, :from => 100, :to => 140},
          :diff_max_time=>{:change => 1.5, :from => 100, :to => 150} }},
      :unmatched_actions => [], 
      :threshold => threshold
    }


    assert_equal(expected, actual)

    ra1 = Request.create('MyCon','MyAc2',600,1,1,1,1)
    rb1 = Request.create('MyCon','MyAc2',610,1,1,1,1)
    ra2 = Request.create('MyCon','MyAc3',50,1,1,1,1)
    rb2 = Request.create('MyCon','MyAc3',50,1,1,1,1)
    @report_a.requests << ra1 << ra2
    @report_b.requests << rb1 << rb2
    assert_equal 3, @report_a.requests.size

    actual=@differ.compare(@report_a, @report_b, threshold)
  end
  def test_prepare_report()
    diff_data = @differ.compare(@report_a, @report_b)
    report_text = @differ.prepare_report(diff_data)
    #TODO: check report text as as we expect
    ##puts report_text
  end

  def test_matched_requests_values_ab
    matches = @differ.find_matched_actions(@report_a, @report_b)
    assert_equal 1, matches.size
    assert_equal [100, 110], matches.first.values_ab(:count)
    assert_equal [100, 120], matches.first.values_ab(:avg_time)
    assert_equal [100, 130], matches.first.values_ab(:std_dev)
    assert_equal [100, 140], matches.first.values_ab(:min_time)
    assert_equal [100, 150], matches.first.values_ab(:max_time)
  end

  def test_find_matched_actions
    matches = @differ.find_matched_actions(@report_a, @report_b)
    assert_equal 1, matches.size
    the_match=matches.first
    assert_equal [@report_a.requests.first, @report_b.requests.first], [the_match.request1, the_match.request2]
    
    #with one of the reports having NO requests
    @report_a.requests.clear
    assert_equal 0, @differ.find_matched_actions(@report_a, @report_b).size
  end
  
  def test_find_unmatched_actions
    #initially, should return empty list - all match
    assert_equal [], @differ.find_unmatched_actions(@report_a, @report_b)
    #add a request to only one report - should find it
    odd_req = Request.create('MyCon','UniqueAction',110,120,130,140,150)
    @report_a.requests << odd_req
    unmatcheds = @differ.find_unmatched_actions(@report_a, @report_b)
    assert_equal 1, unmatcheds.size
    assert_equal 'UniqueAction', unmatcheds.first.request.action
    assert_equal @report_a, unmatcheds.first.report
    
    #add another request (only to rep b)
    odd_req2 = Request.create('UniqueCon','MyAc',110,120,130,140,150)
    @report_b.requests << odd_req2
    unmatcheds = @differ.find_unmatched_actions(@report_a, @report_b)
    assert_equal 2, unmatcheds.size
    assert_equal 'UniqueAction', unmatcheds.first.request.action
    assert_equal @report_a, unmatcheds.first.report
    assert_equal 'UniqueCon', unmatcheds.last.request.controller
    assert_equal @report_b, unmatcheds.last.report
  end

  def test_compare_summaries
    actual=@differ.compare_summaries(@report_a, @report_b)
      assert_equal(
      {
       :diff_count=>{:change => -1.11, :from => 100, :to => 90},
       :diff_avg_time=>{:change => 1.5, :from => 10, :to => 15},
       :diff_std_dev=>{:change => 3.0, :from => 2.0, :to => 6.0},
       :diff_min_time=>{:change => 1, :from => 0.1, :to => 0.1},
       :diff_max_time=>{:change => 2.0, :from => 20.0, :to => 40.0},
       }, actual)
  end
  
  #populate @report_a, @report_b
  def create_reports
    ra = Report.new
    ra.summary.count=100
    ra.summary.avg_time=10.0
    ra.summary.std_dev=2.0
    ra.summary.min_time=0.1
    ra.summary.max_time=20.0

    ca1 = Request.create('MyCon','MyAc',100,100,100,100,100, {:verb=>'get',:format =>'xml'})
    cb1 = Request.create('MyCon','MyAc',110,120,130,140,150, {:verb=>'get',:format =>'xml'})
    ra.requests << ca1

    rb = Report.new
    rb.summary.count=90
    rb.summary.avg_time=15.0
    rb.summary.std_dev=6
    rb.summary.min_time=0.1
    rb.summary.max_time=40.0
    rb.requests << cb1
    @report_a = ra
    @report_b = rb
  end


end

