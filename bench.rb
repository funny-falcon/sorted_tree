require 'benchmark'
require 'sorted_tree'
require 'rbtree'
require 'avl_tree'
require 'red_black_tree'

BIG = 300000.times.map{|i| [rand(100000), i]}
MEDIUM = 10000.times.map{|i| [rand(100000), i]}
SMALL = 20.times.map{|i| [rand(100000), i]}

def insert(klass, arr)
  t = klass.new
  arr.each{|k,v| t[k] = v}
  arr.each{|k,v| t[k]}
  arr.each{|k,v| t.delete(k)}
  raise "fuck #{t.size} #{t.inspect}" unless t.size == 0
end

def big_run(klass)
  insert(klass, BIG)
end

def medium_run(klass)
  30.times do
    insert(klass, MEDIUM)
  end
end

def small_run(klass)
  15000.times do
    insert(klass, SMALL)
  end
end

def run(x, klass)
  x.report("#{klass.name} small"){ small_run(klass) }
  x.report("#{klass.name} medium"){ medium_run(klass) }
  x.report("#{klass.name} big"){ big_run(klass) }
end

Benchmark.bmbm(6) do |x|
  run(x, SortedTree::Map)
  run(x, RBTree)
  run(x, AVLTree)
  run(x, RedBlackTree)
  run(x, Hash)
end
