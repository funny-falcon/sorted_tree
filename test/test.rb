require "sorted_tree"
require "test/unit.rb"

class SortedTreeTest < Test::Unit::TestCase
  def setup
    @sortedtree = SortedTree[*%w(b B d D a A c C)]
  end
  
  def test_new
    assert_nothing_raised {
      SortedTree.new
      SortedTree.new("a")
      SortedTree.new { "a" }
    }
    assert_raises(ArgumentError) { SortedTree.new("a") {} }
    assert_raises(ArgumentError) { SortedTree.new("a", "a") }

    assert_nothing_raised {
      SortedTree.new(&lambda {|a, b|})
      SortedTree.new(&lambda {|*a|})
      SortedTree.new(&lambda {|a, *b|})
      SortedTree.new(&lambda {|a, b, *c|})
    }
    assert_raises(TypeError) { SortedTree.new(&lambda {|a|}) }
    assert_raises(TypeError) { SortedTree.new(&lambda {|a, b, c|}) }
    assert_raises(TypeError) { SortedTree.new(&lambda {|a, b, c, *d|}) }
  end
  
  def test_aref
    assert_equal("A", @sortedtree["a"])
    assert_equal("B", @sortedtree["b"])
    assert_equal("C", @sortedtree["c"])
    assert_equal("D", @sortedtree["d"])
    
    assert_equal(nil, @sortedtree["e"])
    @sortedtree.default = "E"
    assert_equal("E", @sortedtree["e"])
  end
  
  def test_size
    assert_equal(4, @sortedtree.size)
  end
  
  def test_create
    sortedtree = SortedTree[]
    assert_equal(0, sortedtree.size)
    
    sortedtree = SortedTree[@sortedtree]
    assert_equal(4, sortedtree.size)
    assert_equal("A", @sortedtree["a"])
    assert_equal("B", @sortedtree["b"])
    assert_equal("C", @sortedtree["c"])
    assert_equal("D", @sortedtree["d"])
    
    sortedtree = SortedTree[SortedTree.new("e")]
    assert_equal(nil, sortedtree.default)
    sortedtree = SortedTree[SortedTree.new { "e" }]
    assert_equal(nil, sortedtree.default_proc)
    @sortedtree.readjust {|a,b| b <=> a }
    assert_equal(nil, SortedTree[@sortedtree].cmp_proc)
    
    assert_raises(ArgumentError) { SortedTree["e"] }
    
    sortedtree = SortedTree[Hash[*%w(b B d D a A c C)]]
    assert_equal(4, sortedtree.size)
    assert_equal("A", sortedtree["a"])
    assert_equal("B", sortedtree["b"])
    assert_equal("C", sortedtree["c"])
    assert_equal("D", sortedtree["d"])
    
    sortedtree = SortedTree[[%w(a A), %w(b B), %w(c C), %w(d D)]];
    assert_equal(4, sortedtree.size)
    assert_equal("A", sortedtree["a"])
    assert_equal("B", sortedtree["b"])
    assert_equal("C", sortedtree["c"])
    assert_equal("D", sortedtree["d"])
    
    # assert_raises(ArgumentError) { SortedTree[["a"]] }
    
    sortedtree = SortedTree[[["a"]]]
    assert_equal(1, sortedtree.size)
    assert_equal(nil, sortedtree["a"])
    
    # assert_raises(ArgumentError) { SortedTree[[["a", "A", "b", "B"]]] }
  end
  
  def test_clear
    @sortedtree.clear
    assert_equal(0, @sortedtree.size)
  end
  
  def test_aset
    @sortedtree["e"] = "E"
    assert_equal(5, @sortedtree.size)
    assert_equal("E", @sortedtree["e"])
    
    @sortedtree["c"] = "E"
    assert_equal(5, @sortedtree.size)
    assert_equal("E", @sortedtree["c"])
    
    assert_raises(ArgumentError) { @sortedtree[100] = 100 }
    assert_equal(5, @sortedtree.size)
    
    
    key = "f"
    @sortedtree[key] = "F"
    cloned_key = @sortedtree.last[0]
    assert_equal("f", cloned_key)
    assert_not_same(key, cloned_key)
    assert_equal(true, cloned_key.frozen?)
    
    @sortedtree["f"] = "F"
    assert_same(cloned_key, @sortedtree.last[0])

    sortedtree = SortedTree.new
    key = ["g"]
    sortedtree[key] = "G"
    assert_same(key, sortedtree.first[0])
    assert_equal(false, key.frozen?)
  end
  
  def test_clone
    clone = @sortedtree.clone
    assert_equal(4, @sortedtree.size)
    assert_equal("A", @sortedtree["a"])
    assert_equal("B", @sortedtree["b"])
    assert_equal("C", @sortedtree["c"])
    assert_equal("D", @sortedtree["d"])
    
    sortedtree = SortedTree.new("e")
    clone = sortedtree.clone
    assert_equal("e", clone.default)
    
    sortedtree = SortedTree.new { "e" }
    clone = sortedtree.clone
    assert_equal("e", clone.default(nil))
    
    sortedtree = SortedTree.new
    sortedtree.readjust {|a, b| a <=> b }
    clone = sortedtree.clone
    assert_equal(sortedtree.cmp_proc, clone.cmp_proc)
  end
  
  def test_default
    sortedtree = SortedTree.new("e")
    assert_equal("e", sortedtree.default)
    assert_equal("e", sortedtree.default("f"))
    assert_raises(ArgumentError) { sortedtree.default("e", "f") }
    
    sortedtree = SortedTree.new {|tree, key| @sortedtree[key || "c"] }
    assert_equal(nil, sortedtree.default)
    assert_equal("C", sortedtree.default(nil))
    assert_equal("B", sortedtree.default("b"))
  end
  
  def test_set_default
    sortedtree = SortedTree.new { "e" }
    sortedtree.default = "f"
    assert_equal("f", sortedtree.default)
    assert_equal(nil, sortedtree.default_proc)
    
    sortedtree = SortedTree.new { "e" }
    sortedtree.default = nil
    assert_equal(nil, sortedtree.default)
    assert_equal(nil, sortedtree.default_proc)
  end
  
  def test_default_proc
    sortedtree = SortedTree.new("e")
    assert_equal(nil, sortedtree.default_proc)
    
    sortedtree = SortedTree.new { "f" }
    assert_equal("f", sortedtree.default_proc.call)
  end
  
  def test_set_default_proc
    sortedtree = SortedTree.new("e")
    sortedtree.default_proc = Proc.new { "f" }
    assert_equal(nil, sortedtree.default)
    assert_equal("f", sortedtree.default_proc.call)
    
    sortedtree = SortedTree.new("e")
    sortedtree.default_proc = nil
    assert_equal(nil, sortedtree.default)
    assert_equal(nil, sortedtree.default_proc)
    
    if Symbol.method_defined?(:to_proc)
      @sortedtree.default_proc = :upper_bound
      assert_equal(%w(d D), @sortedtree["e"])
    end
    
    assert_raises(TypeError) { sortedtree.default_proc = "f" }
    
    assert_nothing_raised {
      @sortedtree.default_proc = lambda {|a, b|}
      @sortedtree.default_proc = lambda {|*a|}
      @sortedtree.default_proc = lambda {|a, *b|}
      @sortedtree.default_proc = lambda {|a, b, *c|}
    }
    assert_raises(TypeError) { @sortedtree.default_proc = lambda {|a|} }
    assert_raises(TypeError) { @sortedtree.default_proc = lambda {|a, b, c|} }
    assert_raises(TypeError) { @sortedtree.default_proc = lambda {|a, b, c, *d|} }
  end
  
  def test_equal
    assert_equal(SortedTree.new, SortedTree.new)
    assert_equal(@sortedtree, @sortedtree)
    assert_not_equal(@sortedtree, SortedTree.new)
    
    sortedtree = SortedTree[*%w(b B d D a A c C)]
    assert_equal(@sortedtree, sortedtree)
    sortedtree["d"] = "A"
    assert_not_equal(@sortedtree, sortedtree)
    sortedtree["d"] = "D"
    sortedtree["e"] = "E"
    assert_not_equal(@sortedtree, sortedtree)
    @sortedtree["e"] = "E"
    assert_equal(@sortedtree, sortedtree)
    
    sortedtree.default = "e"
    assert_equal(@sortedtree, sortedtree)
    @sortedtree.default = "f"
    assert_equal(@sortedtree, sortedtree)
    
    a = SortedTree.new("e")
    b = SortedTree.new { "f" }
    assert_equal(a, b)
    assert_equal(b, b.clone)
    
    a = SortedTree.new
    b = SortedTree.new
    a.readjust {|x, y| x <=> y }
    assert_not_equal(a, b)
    b.readjust(a.cmp_proc)
    assert_equal(a, b)
    
    #a = SortedTree.new
    #a[1] = a
    #b = SortedTree.new
    #b[1] = b
    #assert_equal(a, b)
  end
  
  def test_fetch
    assert_equal("A", @sortedtree.fetch("a"))
    assert_equal("B", @sortedtree.fetch("b"))
    assert_equal("C", @sortedtree.fetch("c"))
    assert_equal("D", @sortedtree.fetch("d"))
    
    assert_raises(IndexError) { @sortedtree.fetch("e") }
    
    assert_equal("E", @sortedtree.fetch("e", "E"))
    assert_equal("E", @sortedtree.fetch("e") { "E" })
    # assert_equal("E", @sortedtree.fetch("e", "F") { "E" })
    
    assert_raises(ArgumentError) { @sortedtree.fetch }
    assert_raises(ArgumentError) { @sortedtree.fetch("e", "E", "E") }
  end

  def test_key
    assert_equal("a", @sortedtree.key("A"))
    assert_equal(nil, @sortedtree.key("E"))
  end

  def test_empty_p
    assert_equal(false, @sortedtree.empty?)
    @sortedtree.clear
    assert_equal(true, @sortedtree.empty?)
  end
  
  def test_each
    result = []
    @sortedtree.each {|key, val| result << key << val }
    assert_equal(%w(a A b B c C d D), result)
    
    assert_raises(TypeError) {
      @sortedtree.each { @sortedtree["e"] = "E" }
    }
    assert_equal(4, @sortedtree.size)
    
    @sortedtree.each {
      @sortedtree.each {}
      assert_raises(TypeError) {
        @sortedtree["e"] = "E"
      }
      break
    }
    assert_equal(4, @sortedtree.size)
    
    enumerator = @sortedtree.each
    assert_equal(%w(a A b B c C d D), enumerator.to_a.flatten)
  end
  
  def test_each_key
    result = []
    @sortedtree.each_key {|key| result.push(key) }
    assert_equal(%w(a b c d), result)

    assert_raises(TypeError) {
      @sortedtree.each_key { @sortedtree["e"] = "E" }
    }
    assert_equal(4, @sortedtree.size)

    @sortedtree.each_key {
      @sortedtree.each_key {}
      assert_raises(TypeError) {
        @sortedtree["e"] = "E"
      }
      break
    }
    assert_equal(4, @sortedtree.size)
    
    enumerator = @sortedtree.each_key
    assert_equal(%w(a b c d), enumerator.to_a.flatten)
  end
  
  def test_each_value
    result = []
    @sortedtree.each_value {|val| result.push(val) }
    assert_equal(%w(A B C D), result)

    assert_raises(TypeError) {
      @sortedtree.each_value { @sortedtree["e"] = "E" }
    }
    assert_equal(4, @sortedtree.size)

    @sortedtree.each_value {
      @sortedtree.each_value {}
      assert_raises(TypeError) {
        @sortedtree["e"] = "E"
      }
      break
    }
    assert_equal(4, @sortedtree.size)
    
    enumerator = @sortedtree.each_value
    assert_equal(%w(A B C D), enumerator.to_a.flatten)
  end

  def test_shift
    result = @sortedtree.shift
    assert_equal(3, @sortedtree.size)
    assert_equal(%w(a A), result)
    assert_equal(nil, @sortedtree["a"])
    
    3.times { @sortedtree.shift }
    assert_equal(0, @sortedtree.size)
    assert_equal(nil, @sortedtree.shift)
    @sortedtree.default = "e"
    assert_equal("e", @sortedtree.shift)
    
    sortedtree = SortedTree.new { "e" }
    assert_equal("e", sortedtree.shift)
  end
  
  def test_pop
    result = @sortedtree.pop
    assert_equal(3, @sortedtree.size)
    assert_equal(%w(d D), result)
    assert_equal(nil, @sortedtree["d"])
    
    3.times { @sortedtree.pop }
    assert_equal(0, @sortedtree.size)
    assert_equal(nil, @sortedtree.pop)
    @sortedtree.default = "e"
    assert_equal("e", @sortedtree.pop)
    
    sortedtree = SortedTree.new { "e" }
    assert_equal("e", sortedtree.pop)
  end
  
  def test_delete
    result = @sortedtree.delete("c")
    assert_equal("C", result)
    assert_equal(3, @sortedtree.size)
    assert_equal(nil, @sortedtree["c"])
    
    assert_equal(nil, @sortedtree.delete("e"))
    assert_equal("E", @sortedtree.delete("e") { "E" })
  end
  
  def test_delete_if
    result = @sortedtree.delete_if {|key, val| val == "A" || val == "B" }
    assert_same(@sortedtree, result)
    assert_equal(SortedTree[*%w(c C d D)], @sortedtree)
    
    assert_raises(ArgumentError) {
      @sortedtree.delete_if {|key, val| key == "c" or raise ArgumentError }
    }
    assert_equal(1, @sortedtree.size)
    
    assert_raises(TypeError) {
      @sortedtree.delete_if { @sortedtree["e"] = "E" }
    }
    assert_equal(1, @sortedtree.size)

    @sortedtree.delete_if {
      @sortedtree.each {
        assert_equal(1, @sortedtree.size)
      }
      assert_raises(TypeError) {
        @sortedtree["e"] = "E"
      }
      true
    }
    assert_equal(0, @sortedtree.size)
    
    sortedtree = SortedTree[*%w(b B d D a A c C)]
    sortedtree.delete_if.with_index {|(key, val), i| i < 2 }
    assert_equal(SortedTree[*%w(c C d D)], sortedtree)
  end

  def test_keep_if
    result = @sortedtree.keep_if {|key, val| val == "A" || val == "B" }
    assert_same(@sortedtree, result)
    assert_equal(SortedTree[*%w(a A b B)], @sortedtree)
    
    sortedtree = SortedTree[*%w(b B d D a A c C)]
    sortedtree.keep_if.with_index {|(key, val), i| i < 2 }
    assert_equal(SortedTree[*%w(a A b B)], sortedtree)
  end

  def test_reject_bang
    result = @sortedtree.reject! { false }
    assert_equal(nil, result)
    assert_equal(4, @sortedtree.size)
    
    result = @sortedtree.reject! {|key, val| val == "A" || val == "B" }
    assert_same(@sortedtree, result)
    assert_equal(SortedTree[*%w(c C d D)], result)
    
    sortedtree = SortedTree[*%w(b B d D a A c C)]
    sortedtree.reject!.with_index {|(key, val), i| i < 2 }
    assert_equal(SortedTree[*%w(c C d D)], sortedtree)
  end
  
  def test_reject
    result = @sortedtree.reject { false }
    assert_equal(SortedTree[*%w(a A b B c C d D)], result)
    assert_equal(4, @sortedtree.size)
    
    result = @sortedtree.reject {|key, val| val == "A" || val == "B" }
    assert_equal(SortedTree[*%w(c C d D)], result)
    assert_equal(4, @sortedtree.size)
    
    result = @sortedtree.reject.with_index {|(key, val), i| i < 2 }
    assert_equal(SortedTree[*%w(c C d D)], result)
  end

  def test_select_bang
    result = @sortedtree.select! { true }
    assert_equal(nil, result)
    assert_equal(4, @sortedtree.size)
    
    result = @sortedtree.select! {|key, val| val == "A" || val == "B" }
    assert_same(@sortedtree, result)
    assert_equal(SortedTree[*%w(a A b B)], result)
    
    sortedtree = SortedTree[*%w(b B d D a A c C)]
    sortedtree.select!.with_index {|(key, val), i| i < 2 }
    assert_equal(SortedTree[*%w(a A b B)], sortedtree)
  end

  def test_select
    result = @sortedtree.select { true }
    assert_equal(SortedTree[*%w(a A b B c C d D)], result)
    assert_equal(4, @sortedtree.size)
    
    result = @sortedtree.select {|key, val| val == "A" || val == "B" }
    assert_equal(SortedTree[*%w(a A b B)], result)
    assert_raises(ArgumentError) { @sortedtree.select("c") }
    
    result = @sortedtree.select.with_index {|(key, val), i| i < 2 }
    assert_equal(SortedTree[*%w(a A b B)], result)
  end

  def test_values_at
    result = @sortedtree.values_at("d", "a", "e")
    assert_equal(["D", "A", nil], result)
  end
  
  def test_invert
    assert_equal(SortedTree[*%w(A a B b C c D d)], @sortedtree.invert)
  end
  
  def test_update
    sortedtree = SortedTree.new
    sortedtree["e"] = "E"
    @sortedtree.update(sortedtree)
    assert_equal(SortedTree[*%w(a A b B c C d D e E)], @sortedtree)
    
    @sortedtree.clear
    @sortedtree["d"] = "A"
    sortedtree.clear
    sortedtree["d"] = "B"
    
    @sortedtree.update(sortedtree) {|key, val1, val2|
      val1 + val2 if key == "d"
    }
    assert_equal(SortedTree[*%w(d AB)], @sortedtree)
    
    assert_raises(TypeError) { @sortedtree.update("e") }
  end
  
  def test_merge
    sortedtree = SortedTree.new
    sortedtree["e"] = "E"
    
    result = @sortedtree.merge(sortedtree)
    assert_equal(SortedTree[*%w(a A b B c C d D e E)], result)
    
    assert_equal(4, @sortedtree.size)
  end

  def test_flatten
    sortedtree = SortedTree.new
    sortedtree.readjust {|a, b| a.flatten <=> b.flatten }
    sortedtree[["a"]] = ["A"]
    sortedtree[[["b"]]] = [["B"]]
    assert_equal([["a"], ["A"], [["b"]], [["B"]]], sortedtree.flatten)
    assert_equal([["a"], ["A"], [["b"]], [["B"]]], sortedtree.flatten(0))
    assert_equal([["a"], ["A"], [["b"]], [["B"]]], sortedtree.flatten(1))
    assert_equal(["a", "A", ["b"], ["B"]], sortedtree.flatten(2))
    assert_equal(["a", "A", "b", "B"], sortedtree.flatten(3))
    
    assert_raises(TypeError) { @sortedtree.flatten("e") }
    assert_raises(ArgumentError) { @sortedtree.flatten(1, 2) } 
  end

  def test_has_key
    assert_equal(true,  @sortedtree.has_key?("a"))
    assert_equal(true,  @sortedtree.has_key?("b"))
    assert_equal(true,  @sortedtree.has_key?("c"))
    assert_equal(true,  @sortedtree.has_key?("d"))
    assert_equal(false, @sortedtree.has_key?("e"))
  end
  
  def test_has_value
    assert_equal(true,  @sortedtree.has_value?("A"))
    assert_equal(true,  @sortedtree.has_value?("B"))
    assert_equal(true,  @sortedtree.has_value?("C"))
    assert_equal(true,  @sortedtree.has_value?("D"))
    assert_equal(false, @sortedtree.has_value?("E"))
  end

  def test_keys
    assert_equal(%w(a b c d), @sortedtree.keys)
  end

  def test_values
    assert_equal(%w(A B C D), @sortedtree.values)
  end

  def test_to_a
    assert_equal([%w(a A), %w(b B), %w(c C), %w(d D)], @sortedtree.to_a)
  end

  def test_to_hash
    @sortedtree.default = "e"
    hash = @sortedtree.to_hash
    assert_equal(@sortedtree.to_a.flatten, hash.sort_by {|key, val| key}.flatten)
    assert_equal("e", hash.default)

    sortedtree = SortedTree.new { "e" }
    hash = sortedtree.to_hash
    if (hash.respond_to?(:default_proc))
      assert_equal(sortedtree.default_proc, hash.default_proc)
    else
      assert_equal(sortedtree.default_proc, hash.default)
    end
  end

  def test_to_sortedtree
    assert_same(@sortedtree, @sortedtree.to_sortedtree)
  end
  
  def test_inspect
    [:to_s, :inspect].each do |method|
      @sortedtree.default = "e"
      @sortedtree.readjust {|a, b| a <=> b}
      re = /#<SortedTree::Map: (\{.*\}), default=(.*), cmp_proc=(.*)>/
      
      assert_match(re, @sortedtree.send(method))
      match = re.match(@sortedtree.send(method))
      tree, default, cmp_proc = match.to_a[1..-1]
      assert_equal(%({"a"=>"A", "b"=>"B", "c"=>"C", "d"=>"D"}), tree)
      assert_equal(%("e"), default)
      assert_match(/#<Proc:\w+(@#{__FILE__}:\d+)?>/o, cmp_proc)
      
      sortedtree = SortedTree.new
      assert_match(re, sortedtree.send(method))
      match = re.match(sortedtree.send(method))
      tree, default, cmp_proc = match.to_a[1..-1]
      assert_equal("{}", tree)
      assert_equal("nil", default)
      assert_equal("nil", cmp_proc)
      
      #sortedtree = SortedTree.new
      #sortedtree[sortedtree] = sortedtree
      #sortedtree.default = sortedtree
      #match = re.match(sortedtree.send(method))
      #tree, default, cmp_proc =  match.to_a[1..-1]
      #assert_equal("{#<SortedTree: ...>=>#<SortedTree: ...>}", tree)
      #assert_equal("#<SortedTree: ...>", default)
      #assert_equal("nil", cmp_proc)
    end
  end
  
  def test_lower_bound
    sortedtree = SortedTree[*%w(a A c C e E)]
    assert_equal(%w(c C), sortedtree.lower_bound("c"))
    assert_equal(%w(c C), sortedtree.lower_bound("b"))
    assert_equal(nil, sortedtree.lower_bound("f"))
  end
  
  def test_upper_bound
    sortedtree = SortedTree[*%w(a A c C e E)]
    assert_equal(%w(c C), sortedtree.upper_bound("c"))
    assert_equal(%w(c C), sortedtree.upper_bound("d"))
    assert_equal(nil, sortedtree.upper_bound("Z"))
  end
  
  def test_bound
    sortedtree = SortedTree[*%w(a A c C e E)]
    b = sortedtree.bound('a', 'c')
    assert_equal(%w(a A c C), sortedtree.bound("a", "c").to_a.flatten)
    assert_equal(%w(a A),     sortedtree.bound("a").to_a.flatten)
    assert_equal(%w(c C e E), sortedtree.bound("b", "f").to_a.flatten)

    assert_equal([], sortedtree.bound("b", "b").to_a)
    assert_equal([], sortedtree.bound("Y", "Z").to_a)
    assert_equal([], sortedtree.bound("f", "g").to_a)
    assert_equal([], sortedtree.bound("f", "Z").to_a)
    
    if defined?(Enumerator) and Enumerator.method_defined?(:size)
      assert_equal(2, sortedtree.bound("a", "c").size)
      assert_equal(1, sortedtree.bound("a").size)
      assert_equal(2, sortedtree.bound("b", "f").size)
      
      assert_equal(0, sortedtree.bound("b", "b").size)
      assert_equal(0, sortedtree.bound("Y", "Z").size)
      assert_equal(0, sortedtree.bound("f", "g").size)
      assert_equal(0, sortedtree.bound("f", "Z").size)
    end
  end
  
  def test_bound_block
    result = []
    @sortedtree.bound("b", "c") {|key, val|
      result.push(key)
    }
    assert_equal(%w(b c), result)
    
    assert_raises(TypeError) {
      @sortedtree.bound("a", "d") {
        @sortedtree["e"] = "E"
      }
    }
    assert_equal(4, @sortedtree.size)
    
    @sortedtree.bound("b", "c") {
      @sortedtree.bound("b", "c") {}
      assert_raises(TypeError) {
        @sortedtree["e"] = "E"
      }
      break
    }
    assert_equal(4, @sortedtree.size)
  end
  
  def test_first
    assert_equal(%w(a A), @sortedtree.first)
    
    sortedtree = SortedTree.new("e")
    assert_equal("e", sortedtree.first)

    sortedtree = SortedTree.new { "e" }
    assert_equal("e", sortedtree.first)
  end

  def test_last
    assert_equal(%w(d D), @sortedtree.last)
    
    sortedtree = SortedTree.new("e")
    assert_equal("e", sortedtree.last)

    sortedtree = SortedTree.new { "e" }
    assert_equal("e", sortedtree.last)
  end

  def test_readjust
    assert_equal(nil, @sortedtree.cmp_proc)
    
    @sortedtree.readjust {|a, b| b <=> a }
    assert_equal(%w(d c b a), @sortedtree.keys)
    assert_not_equal(nil, @sortedtree.cmp_proc)
    
    proc = Proc.new {|a,b| a.to_s <=> b.to_s }
    @sortedtree.readjust(proc)
    assert_equal(%w(a b c d), @sortedtree.keys)
    assert_equal(proc, @sortedtree.cmp_proc)
    
    @sortedtree[0] = nil
    assert_raises(ArgumentError) { @sortedtree.readjust(nil) }
    assert_equal(5, @sortedtree.size)
    assert_equal(proc, @sortedtree.cmp_proc)
    
    @sortedtree.delete(0)
    @sortedtree.readjust(nil)
    assert_raises(ArgumentError) { @sortedtree[0] = nil }
    
    if Symbol.method_defined?(:to_proc)
      sortedtree = SortedTree[*%w(a A B b)]
      assert_equal(%w(B b a A), sortedtree.to_a.flatten)
      sortedtree.readjust(:casecmp)
      assert_equal(%w(a A B b), sortedtree.to_a.flatten)
    end
    
    assert_nothing_raised {
      @sortedtree.readjust(lambda {|a, b| a <=> b })
      @sortedtree.readjust(lambda {|*a| a[0] <=> a[1] })
      @sortedtree.readjust(lambda {|a, *b| a <=> b[0] })
      @sortedtree.readjust(lambda {|a, b, *c| a <=> b })
      @sortedtree.readjust(&lambda {|a, b| a <=> b })
      @sortedtree.readjust(&lambda {|*a| a[0] <=> a[1] })
      @sortedtree.readjust(&lambda {|a, *b| a <=> b[0] })
      @sortedtree.readjust(&lambda {|a, b, *c| a <=> b })
    }
    assert_raises(TypeError) { @sortedtree.readjust(lambda {|a| 1 }) }
    assert_raises(TypeError) { @sortedtree.readjust(lambda {|a, b, c| 1 }) }
    assert_raises(TypeError) { @sortedtree.readjust(lambda {|a, b, c, *d| 1 }) }
    assert_raises(TypeError) { @sortedtree.readjust(&lambda {|a| 1 }) }
    assert_raises(TypeError) { @sortedtree.readjust(&lambda {|a, b, c| 1 }) }
    assert_raises(TypeError) { @sortedtree.readjust(&lambda {|a, b, c, *d| 1 }) }


    sortedtree = SortedTree.new
    key = ["a"]
    sortedtree[key] = nil
    sortedtree[["e"]] = nil
    key[0] = "f"

    assert_equal([["f"], ["e"]], sortedtree.keys)
    sortedtree.readjust
    assert_equal([["e"], ["f"]], sortedtree.keys)

    assert_raises(TypeError) { @sortedtree.readjust("e") }
    assert_raises(ArgumentError) {
      @sortedtree.readjust(proc) {|a,b| a <=> b }
    }
    assert_raises(ArgumentError) { @sortedtree.readjust(proc, proc) }


    sortedtree = SortedTree[("a".."z").to_a.zip(("A".."Z").to_a)]
    assert_nothing_raised do
      sortedtree.readjust do |a, b|
        ObjectSpace.each_object(SortedTree) do |temp|
          temp.clear if temp.size == sortedtree.size - 1
        end
        a <=> b
      end
    end
  end
  
  def test_replace
    sortedtree = SortedTree.new { "e" }
    sortedtree.readjust {|a, b| a <=> b}
    sortedtree["a"] = "A"
    sortedtree["e"] = "E"
    
    @sortedtree.replace(sortedtree)
    assert_equal(%w(a A e E), @sortedtree.to_a.flatten)
    assert_equal(sortedtree.default, @sortedtree.default)    
    assert_equal(sortedtree.cmp_proc, @sortedtree.cmp_proc)

    assert_raises(TypeError) { @sortedtree.replace("e") }
  end
  
  def test_reverse_each
    result = []
    @sortedtree.reverse_each { |key, val| result.push([key, val]) }
    assert_equal(%w(d D c C b B a A), result.flatten)
    
    enumerator = @sortedtree.reverse_each
    assert_equal(%w(d D c C b B a A), enumerator.to_a.flatten)
  end
  
  def test_marshal
    assert_equal(@sortedtree, Marshal.load(Marshal.dump(@sortedtree)))
    
    @sortedtree.default = "e"
    assert_equal(@sortedtree, Marshal.load(Marshal.dump(@sortedtree)))
    
    assert_raises(TypeError) {
      Marshal.dump(SortedTree.new { "e" })
    }
    
    assert_raises(TypeError) {
      @sortedtree.readjust {|a, b| a <=> b}
      Marshal.dump(@sortedtree)
    }
  end

  def test_modify_in_cmp_proc
    can_clear = false
    @sortedtree.readjust do |a, b|
      @sortedtree.clear if can_clear
      a <=> b
    end
    can_clear = true
    assert_raises(TypeError) { @sortedtree["e"] }
  end
  
  begin
    require "pp"
    
    def test_pp
      assert_equal(%(#<SortedTree::Map: {}, default=nil, cmp_proc=nil>\n),
                   PP.pp(SortedTree.new, ""))
      assert_equal(%(#<SortedTree::Map: {"a"=>"A", "b"=>"B"}, default=nil, cmp_proc=nil>\n),
                   PP.pp(SortedTree[*%w(a A b B)], ""))
      
      sortedtree = SortedTree[*("a".."z").to_a]
      sortedtree.default = "a"
      sortedtree.readjust {|a, b| a <=> b }
      expected = <<EOS
#<SortedTree::Map: {"a"=>"b",
  "c"=>"d",
  "e"=>"f",
  "g"=>"h",
  "i"=>"j",
  "k"=>"l",
  "m"=>"n",
  "o"=>"p",
  "q"=>"r",
  "s"=>"t",
  "u"=>"v",
  "w"=>"x",
  "y"=>"z"},
 default="a",
 cmp_proc=#{sortedtree.cmp_proc}>
EOS
      assert_equal(expected, PP.pp(sortedtree, ""))

      sortedtree = SortedTree.new
      sortedtree[sortedtree] = sortedtree
      sortedtree.default = sortedtree
      expected = <<EOS
#<SortedTree: {"#<SortedTree: ...>"=>"#<SortedTree: ...>"},
 default="#<SortedTree: ...>",
 cmp_proc=nil>
EOS
      assert_equal(expected, PP.pp(sortedtree, ""))
    end
  rescue LoadError
  end
end


