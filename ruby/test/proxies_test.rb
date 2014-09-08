require_relative "test_helper"

class ProxyTest < MiniTest::Unit::TestCase
  def test_retrieve_proxies_from_clean_toxiproxy
    assert_predicate Toxiproxy::Proxy.all, :empty?
  end

  def test_create_proxy
    proxy = Toxiproxy::Proxy.create(upstream: "localhost:3306", name: "mysql_master")

    proxy = Toxiproxy::Proxy.all.last
    assert_equal "localhost:3306", proxy.upstream
    assert_equal "mysql_master", proxy.name
  end

  def test_create_and_delete_proxy
    proxy = Toxiproxy::Proxy.create(upstream: "localhost:3306", 
                                    name: "mysql_master")
    assert Toxiproxy["mysql_master"]
    assert proxy.destroy
    refute Toxiproxy["mysql_master"]
  end

  def test_create_proxy_and_connect_through_it
    with_tcpserver do |port|
      proxy = Toxiproxy::Proxy.create(upstream: "localhost:#{port}", 
                                      name: "rubby_server")

      TCPSocket.new(*proxy.proxy.split(":"))

      proxy.destroy

      assert_raises Errno::ECONNREFUSED do
        TCPSocket.new(*proxy.proxy.split(":"))
      end
    end
  end

  def test_use_state_to_take_endpoint_down
    with_tcpserver do |port|
      proxy = Toxiproxy::Proxy.create(upstream: "localhost:#{port}", 
                                      name: "rubby_server")

      proxy.state(:down) do
        assert_raises Errno::ECONNREFUSED do
          TCPSocket.new(*proxy.proxy.split(":"))
        end
      end

      TCPSocket.new(*proxy.proxy.split(":"))
    end
  end
end
