require_relative 'helper'

setup do
  Dominate.reset_config!
  Dominate.setup do |c|
    c.view_path = './test/dummy'
    c.layout    = "app"
    c.parse_dom = true
  end

  inline_html = File.read './test/dummy/index.html'

  instance = OpenStruct.new({
    current_user: OpenStruct.new({
      first_name: 'CJ',
      last_name: 'Lazell'
    })
  })

  OpenStruct.new({
    current_user: instance.current_user,
    dom: Dominate::HTML(inline_html, instance),
  })
end

scope 'dominate template' do
  test 'html' do |a|
    assert a.dom.html['test']
    assert a.dom.html.scan(/<a.*>/).length == 2
  end

  test 'data' do |a|
    a.dom.scope(:list).apply([
      { todo: 'get milk' },
      { todo: 'get cookies' },
      { todo: 'work out' },
    ])

    assert a.dom.html['test'] == nil
    assert a.dom.html.scan(/<a.*>/).length == 3
    assert a.dom.html['get milk']
    assert a.dom.html['get cookies']
  end

  test 'context' do |a|
    assert a.dom.html['John'] == nil
    assert a.dom.html['CJ']
  end

  test 'blocks' do |a|
    a.dom.scope(:admin_only) do |node|
      unless a.current_user.admin
        node.remove
      end
    end
    assert a.dom.html['Admin'] == nil
  end

  test 'procs' do |a|
    data = [
      {todo: -> {
        current_user.admin ? 'do admin stuff' : 'do normal person stuff'}
      },
      {todo: ->(d) { d.length }
      }
    ]

    a.dom.scope(:list).apply(data)
    assert a.dom.html['do normal person stuff']
  end

  test 'partial' do |a|
    data = {
      company: {
        name: 'Test Company'
      }
    }

    a.dom.scope(:footer).apply data
    assert a.dom.html['Test Company']
    assert a.dom.html['This should not show'] == nil
  end

  test 'layout' do |a|
    assert a.dom.html['<head>'] == nil
    assert a.dom.html['body']
    assert a.dom.html['app layout']
    assert a.dom.html.scan(/body/).length == 2
  end

  test 'file' do
    dom = Dominate::HTML.file 'index'
    assert dom.html['data-scope']
  end

  test 'flat' do
    dom = Dominate::HTML.file 'flat', false, name: '.dom'
    dom.scope(:flat).apply ['moo', 'cow']
    assert dom.html['Moo']
    assert dom.html['Cow']
  end

  test 'styles' do
    dom = Dominate::HTML.file 'flat', false, name: '.dom'

    dom.scope(:flat).apply ['moo', 'cow'] do |node|
      styles          = node.styles
      styles['color'] = '#000'

      node.styles = styles
    end

    assert dom.html['#000']
    assert dom.html['added via .dom file']
  end

  test 'raise' do
    assert_raise(Dominate::NoFileFound) do
      Dominate::HTML.file 'no_file', false, name: '.dom'
    end
  end
end
