require 'sinatra'
require 'haml'
require 'yaml'
require 'rexml/document'

def clear_params str
  # brackets have special meaning with request parameters
  str.tr('[]', '()')
end

# extracts mapping from metadata embedded within "v:" attributes
def get_map xml_doc
  map = {}
  xml_doc.elements.each('//*') do |elem|
    path = clear_params(elem.xpath)
    if attr=elem.attribute('v:text')
      map[path] = attr.value
    elsif attr=elem.attribute('v:choice')
      map[path] = attr.value.split(',')
    end
  end
  map
end

xml_file_name = 'examples/example1.xml'
xml_file = File.read(xml_file_name)
xml_map = get_map(REXML::Document.new(xml_file))

get '/' do
  haml :index, :locals => {:xml_map => xml_map}
end

post '/' do
  doc = REXML::Document.new(xml_file)

  doc.elements.each('//*') do |elem|
    path = clear_params(elem.xpath)
    if params[path]
      elem.text = params[path]
    end
  end

  haml :xml, :locals => {:xml => doc.to_s}
end

__END__

@@ layout
%html
  =yield

@@ index
%form{:method => :post}
  %dl
    -xml_map.each do |xpath, vals|
      %dt
        =xpath
      %dd
        -if vals.is_a? Array
          %select{:id => xpath, :name => xpath}
            -vals.each do |val|
              %option
                =val
        -else
          %input{:id => xpath, :value => vals, :name => xpath}
  %input{:type => :submit}

@@ xml
%pre&~ xml
