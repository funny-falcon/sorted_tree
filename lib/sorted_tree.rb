require "sorted_tree/version"
require "sorted_tree/pages"

module SortedTree
  def self.new(*args, &proc)
    Map.new(*args, &proc)
  end

  def self.[](*args, &proc)
    Map[*args, &proc]
  end

  class Map
    include Enumerable
    NONE = Object.new.freeze
    ACCEPT_ARITY = [2, -1, -2, -3]
    attr :tree
    def initialize(default = nil, &default_proc)
      if default && default_proc
        raise ArgumentError, "give default or default_proc, not both"
      end
      if default_proc && default_proc.lambda? && !ACCEPT_ARITY.include?(default_proc.arity)
        raise TypeError, "default_proc takes two arguments (2 for #{default_proc.arity}"
      end
      @default = default
      @default_proc = default_proc
      @tree = Tree.new(false)
      @iter_lev = 0
    end

    attr :default_proc
    def default(k = NONE)
      if k.equal? NONE
        @default
      else
        @default != nil ? @default : 
          (@default_proc && @default_proc.call(self, k))
      end
    end

    def default=(v)
      @default_proc = nil
      @default = v
    end

    def default_proc=(v)
      unless !v || v.respond_to?(:call)
        unless v.respond_to?(:to_proc)
          raise(TypeError, "default_proc should respond to #call or #to_proc")
        end
        v = v.to_proc
        unless v.respond_to?(:call)
          raise(TypeError, "default_proc.to_proc should return callable")
        end
      end
      unless !v || (v.respond_to?(:lambda?) ?
          !v.lambda? || ACCEPT_ARITY.include?(v.arity) :
          ACCEPT_ARITY.include?(v.method(:call).arity))
        raise TypeError, "default_proc should have arity 2"
      end
      @default = nil
      @default_proc = v
    end

    def self.[](*args)
      if args.size == 1 && args[0].respond_to?(:each)
        t = self.new
        args[0].each{|pair|
          t[pair[0]] = pair[1] if Array === pair
        }
        t
      else
        if args.size & 1 == 1
          raise ArgumentError, "odd number of arguments for SortedTree"
        end
        t = self.new
        i = 0
        while i < args.size
          t[args[i]] = args[i+1]
          i += 2
        end
        t
      end
    end

    def [](k)
      @iter_lev += 1
      a = @tree.get(k, NONE)
      !a.equal?(NONE) ? a : default(k)
    ensure
      @iter_lev -= 1
    end

    def _modify
      if @iter_lev > 0
        raise TypeError, "could not modify during iteration"
      end
    end

    def []=(k,v)
      _modify
      k = k.clone.freeze if String === k
      @tree.put(k,v)
      v
    end

    def readjust(cmp=nil, &bl)
      _modify
      if cmp && bl
        raise ArgumentError, "readjust cannot accept both value and block"
      end
      cmp ||= bl
      unless cmp == nil
        if !(Proc === cmp) && cmp.respond_to?(:to_proc)
          cmp = cmp.to_proc
        end
        if !(Proc === cmp)
          raise TypeError, "readjust should be a proc or respond to :to_proc, got #{cmp.inspect}"
        end
        if Proc === cmp && cmp.lambda? && !ACCEPT_ARITY.include?(cmp.arity)
          raise TypeError, "readjust takes two arguments (2 for #{cmp.arity}"
        end
      end
      new_tree = Tree.new(false, cmp)
      @tree.each{|k,v| new_tree.put(k,v)}
      @tree = new_tree
    end

    def each
      return to_enum unless block_given?
      begin
        @iter_lev += 1
        @tree.each{|*p| yield p}
      ensure
        @iter_lev -= 1
      end
    end

    def clear
      _modify
      @tree = Tree.new(false, @tree.cmp_proc)
    end

    def self.proxy(nargs, *meths)
      args = nargs.times.map{|i| "a#{i}"}.join(", ")
      meths.each do |meth|
        class_eval <<-"EOF"
          def #{meth}(#{args})
            @tree.#{meth}(#{args})
          end
        EOF
      end
    end
    proxy 0, :size, :cmp_proc
    alias length size
    proxy 1, :upper_bound, :lower_bound
    proxy 0, :keys, :values
    proxy 0, :empty?, :to_a

    def first
      if @tree.size == 0
        default(nil)
      else
        @tree.first
      end
    end

    def last
      if @tree.size == 0
        default(nil)
      else
        @tree.last
      end
    end

    def shift
      _modify
      return default(nil) if @tree.size == 0
      @tree.shift
    end

    def pop
      _modify
      return default(nil) if @tree.size == 0
      @tree.pop
    end

    def ==(o)
      return false unless o.class == self.class
      @tree == o.tree
    end

    def fetch(k, default = NONE, &block)
      v = @tree.get(k, NONE)
      if v == NONE
        if default == NONE
          unless block
            raise IndexError, "key not found: #{k.inspect}"
          end
          block.call(k)
        else
          default
        end
      else
        v
      end
    end

    def key(val)
      each{|k,v| return k if v == val}
      nil
    end

    def each_key
      return to_enum(:each_key) unless block_given?
      each{|k,v| yield k}
    end

    def each_value
      return to_enum(:each_value) unless block_given?
      each{|k,v| yield v}
    end

    def delete(k)
      _modify
      v = @tree.delete(k, NONE)
      if v.equal?(NONE)
        if block_given?
          yield k
        end
      else
        v
      end
    end

    def delete_if
      return to_enum(:delete_if) unless block_given?
      keep_if{|k,v| !yield(k,v)}
    end

    def keep_if
      return to_enum(:keep_if) unless block_given?
      _modify
      begin
        @iter_lev += 1
        @tree.keep_if{|k,v| yield(k,v)}
      ensure
        @iter_lev -= 1
      end
      self
    end

    def reject!
      return to_enum(:reject!) unless block_given?
      _modify
      n = @tree.size
      delete_if{|k,v| yield(k,v)}
      n == @tree.size ? nil : self
    end

    def reject
      return to_enum(:reject) unless block_given?
      t = self.class.new()
      t.readjust @tree.cmp_proc
      each{|k,v| t[k] = v unless yield(k,v)}
      t
    end

    def select
      return to_enum(:select) unless block_given?
      t = self.class.new()
      t.readjust @tree.cmp_proc
      each{|k,v| t[k] = v if yield(k,v)}
      t
    end

    def select!
      return to_enum(:select!) unless block_given?
      _modify
      n = @tree.size
      keep_if{|k,v| yield(k,v)}
      n == @tree.size ? nil : self
    end

    def values_at(*args)
      args.map{|k| self[k]}
    end

    def invert
      t = self.class.new
      each{|k,v| t[v] = k}
      t
    end

    def update(oth)
      unless oth.respond_to?(:each)
        raise TypeError, "other should respond to each"
      end
      _modify
      if block_given?
        oth.each{|k,nv|
          unless (ov = @tree.get(k, NONE)).equal?(NONE)
            @tree.put(k, yield(k, ov, nv))
          else
            @tree.put(k, nv)
          end
        }
      else
        oth.each{|k,nv| @tree.put(k, nv) }
      end
      self
    end
    alias merge! update

    def merge(oth)
      t = clone
      if block_given?
        t.update(oth){|k, ov, nv| yield k, ov, nv}
      else
        t.update(oth)
      end
    end

    def initialize_copy(old)
      @iter_lev = 0
      @tree = @tree.dup
    end

    def flatten(level = nil)
      res = []
      each{|k,v| res.push(k,v)}
      if level
        unless Integer === level
          raise TypeError, "level should be Integer"
        end
        if level > 1
          res.flatten!(level - 1)
        end
      end
      res
    end

    def has_key?(k)
      !@tree.get(k, NONE).equal?(NONE)
    end

    def has_value?(v)
      each{|k,hv| return true if v == hv}
      false
    end

    def to_hash
      h = {}
      if @default
        h.default = @default
      elsif @default_proc
        h.default_proc = @default_proc
      end
      each{|k, hv| h[k] = hv}
      h
    end

    def to_sortedtree
      self
    end

    def to_s
      kv = map{|k,v| "#{k.inspect}=>#{v.inspect}"}
      out = "#<SortedTree::Map: {#{kv.join(', ')}}"
      out << ", default=#{@default.inspect}"
      if @default_proc
        out << ", default_proc=#{@default_proc.inspect}"
      end
      out << ", cmp_proc=#{cmp_proc.inspect}>"
    end
    alias inspect to_s

    if (Enumerator.instance_method(:size) rescue false)
      def bound(from, to = from)
        unless block_given?
          sz = lambda{@tree.bound_size(from, to, true)}
          return Enumerator.new(sz){|y|
            bound(from, to){|k, v| y.yield k, v}
          }
        end
        begin
          @iter_lev += 1
          @tree.bound(from, to, true){|k, v| yield k, v}
        ensure
          @iter_lev -= 1
        end
      end
    else
      def bound(from, to = from)
        unless block_given?
          return Enumerator.new{|y|
            bound(from, to){|k, v| y.yield k, v}
          }
        end
        begin
          @iter_lev += 1
          @tree.bound(from, to, true){|k, v| yield k, v}
        ensure
          @iter_lev -= 1
        end
      end
    end

    def replace(oth)
      unless self.class == oth.class
        raise TypeError
      end
      _modify
      @iter_lev = 0
      @default = oth.default
      @default_proc = oth.default_proc
      @tree = oth.tree.dup
    end

    def reverse_each
      return to_enum(:reverse_each) unless block_given?
      begin
        @iter_lev += 1
        @tree.reverse_each{|k,v| yield k, v}
      ensure
        @iter_lev -= 1
      end
    end
  end
end
