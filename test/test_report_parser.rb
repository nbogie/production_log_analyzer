#!/usr/bin/env ruby

require 'test/unit'

require 'report/report_parser'

class TestReportParser < Test::Unit::TestCase

  def file_data(filename)
    'test/example_data/' + filename
  end

  def setup
    @parser = ReportParser.new
  end

  def test_initialization
    parser = ReportParser.new
  end

  def test_can_parse_report
    content = File.read(file_data('example.txt'))
                       
    result = @parser.parse("my report name", content)
    assert_not_nil(result)
    assert_equal("my report name", result.name)
    assert_equal(8, result.requests.size)
    expected_controllers= %w(
                          FooController
                          FooController
                          FooController
                          FooController
                          BarController
                          HealthController
                          QuxController
                          UsersController)
    assert_equal(expected_controllers, result.requests.map{|rq| rq.controller})
  end

  def test_can_extract_from_all_requests
    content = File.read(file_data('example.txt'))
    result = @parser.parse("whatever", content)
    assert_equal(11830,result.summary.count)
    assert_equal(0.185,result.summary.avg_time)
    assert_equal(0.212,result.summary.std_dev)
    assert_equal(0.001,result.summary.min_time)
    assert_equal(3.553,result.summary.max_time)
  end

  def test_can_parse_a_request
    line = "ApiFooController#update.PUT.xml:       3557    0.144   0.137   0.059   3.212"
    request = @parser.parse_request(line)
    assert_equal("ApiFooController",request.controller)
    assert_equal("update",request.action)
    assert_equal("PUT",request.verb)
    assert_equal("xml",request.format)
    assert_equal(3557,request.count)
    assert_equal(0.144,request.avg_time)
    assert_equal(0.137,request.std_dev)
    assert_equal(0.059,request.min_time)
    assert_equal(3.212,request.max_time)
  end

  def test_should_normalize_request_format_to_lowercase
    line = "ApiFooController#update.PUT.XmL:       3557    0.144   0.137   0.059   3.212"
    request = @parser.parse_request(line)
    assert_equal("xml",request.format)
  end

  def test_should_normalize_request_verb_to_uppercase
    line = "ApiFooController#update.puT.xml:       3557    0.144   0.137   0.059   3.212"
    request = @parser.parse_request(line)
    assert_equal("PUT",request.verb)
  end

  def test_should_parse_request_having_no_format
    line = "ApiFooController#update.GET:       3557    0.144   0.137   0.059   3.212"
    request = @parser.parse_request(line)
    assert_equal("GET",request.verb)
    assert_nil(request.format)
    assert_equal(0.144,request.avg_time)
  end

  def test_can_parse_a_request_having_module_named_controller_name
    line = "Api::V1::FooController#show.GET:       11707   0.107   0.263   0.015   19.075"
    request = @parser.parse_request(line)
    assert_equal("Api::V1::FooController",request.controller)
  end

  def test_should_parse_a_few_lines
   should_parse "QuxController#index.GET.rss:           	5	0.241	0.078	0.121	0.367" 
  end

  def should_parse(line)
    @parser.parse_request(line)
  end

end
  
class TestRequest < Test::Unit::TestCase
  def test_remembers_its_values
    r = Request.new
    r.controller = "somecontroller"
    r.action = "someaction"
    r.verb = "GET"
    r.format = "xml"
    r.count = 100
    r.avg_time = 1.123
    r.std_dev = 0.22
    r.min_time = 3.33
    r.max_time = 10.10
    assert_equal("somecontroller",r.controller)
    assert_equal("someaction",r.action)
    assert_equal("GET",r.verb)
    assert_equal("xml",r.format)
    assert_equal(3.33,r.min_time)
    assert_equal(10.10,r.max_time)
    assert_equal(1.123,r.avg_time)
    assert_equal(0.22,r.std_dev)
  end

  def test_create
    req = Request.create('Con','Ac',1,2,3,4,5, {:verb=>'get',:format =>'xml'})
    assert_equal('Con', req.controller)
    assert_equal('Ac', req.action)
    assert_equal(1, req.count)
    assert_equal(2, req.avg_time)
    assert_equal(3, req.std_dev)
    assert_equal(4, req.min_time)
    assert_equal(5, req.max_time)
  end

  def test_should_not_fixup_already_fixed_up_name
    r = Request.new
    r.controller =  "Api::V1::GraultController"
    r.fixup_controller_name!
    assert_equal("Api::V1::GraultController",r.controller)
  end
end

