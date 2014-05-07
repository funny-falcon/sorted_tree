module SortedTree
  class Tree
    MIN = 127
    MAX = 256

    attr :size, :first_leaf
    def initialize(set = false, cmp_key = nil)
      @set = set
      @root = set ? SetLeaf.new() : MapLeaf.new()
      @first_leaf = @root
      @cmp_key = cmp_key
      @size = 0
    end

    def cmp_proc
      @cmp_key
    end

    def empty?
      @size == 0
    end

    def []=(k,v)
      put(k,v)
    end

    def [](k)
      get(k)
    end

    def put(k, v)
      _fix_root
      leaf = leaf_le_fix(k)
      if leaf == nil
        @first_leaf.insert_kv(0, k, v)
        @size += 1
      else
        pos = _page_first_ge(leaf, k)
        if pos < leaf.amount && cmp_key(leaf.key_at(pos), k) == 0
          leaf.set_value(pos, v)
        else
          leaf.insert_kv(pos, k, v)
          @size += 1
        end
      end
    end

    def delete(k, default = nil)
      _fix_root
      leaf = leaf_le_fix(k)
      if leaf != nil
        pos = _page_first_ge(leaf, k)
        if pos < leaf.amount && cmp_key(leaf.key_at(pos), k) == 0
          @size -= 1
          return leaf.delete_kv(pos)
        end
      end
      default
    end

    def get(k, default = nil)
      leaf = leaf_le(k)
      if leaf
        pos = _page_first_ge(leaf, k)
        if pos < leaf.amount && cmp_key(leaf.key_at(pos), k) == 0
          return leaf.value_at(pos)
        end
      end
      default
    end

    def keys
      leaf = @first_leaf
      out = []
      leaf.push_keys(0, -1, out)
      while leaf = leaf.next
        leaf.push_keys(0, -1, out)
      end
      out
    end

    def values
      leaf = @first_leaf
      out = []
      leaf.push_values(0, -1, out)
      while leaf = leaf.next
        leaf.push_values(0, -1, out)
      end
      out
    end

    def to_a
      leaf = @first_leaf
      out = []
      leaf.push_items(0, -1, out)
      while leaf = leaf.next
        leaf.push_items(0, -1, out)
      end
      out
    end

    def each
      leaf = @first_leaf
      step = @set ? 1 : 2
      while leaf
        i = 2
        while i < leaf.size
          if step == 2
            yield leaf[i], leaf[i+1]
          else
            yield leaf[i]
          end
          i += step
        end
        leaf = leaf.next
      end
      self
    end

    def reverse_each
      leaf = _last_page
      step = @set ? 1 : 2
      while leaf
        i = leaf.amount * step + 2
        while i > 2
          i -= step
          if step == 2
            yield leaf[i], leaf[i+1]
          else
            yield leaf[i]
          end
        end
        leaf = leaf.prev
      end
      self
    end

    def bound(from, to, include_end)
      if from != nil
        it = last_lt(from, false)
      else
        it = [nil, nil]
      end
      _next_pos(it)
      while it[0]
        if to != nil
          k = it[0].key_at(it[1])
          c = cmp_key(k, to)
          break if include_end ? c > 0 : c >= 0
        end
        yield *it[0].item_at(it[1])
        _next_pos(it)
      end
    end

    def bound_size(from, to, include_end)
      leaf, start = _next_pos(last_lt(from, false))
      return 0 if leaf == nil
      size = 0
      while leaf
        c = cmp_key(leaf.key_at(leaf.amount-1), to)
        if include_end ? c <= 0 : c < 0
          size += leaf.amount - start
          leaf = leaf.next
          start = 0
        else
          if include_end
            stop = _page_first_gt(leaf, to)
          else
            stop = _page_first_ge(leaf, to)
          end
          return size + (stop - start)
        end
      end
      return size
    end

    def upper_bound(key)
      leaf = leaf_le(key)
      return nil unless leaf
      pos = _page_first_gt(leaf, key)
      pos > 0 ? leaf.item_at(pos-1) : nil
    end

    def lower_bound(key)
      it = last_lt(key, false)
      _next_pos(it)
      it[0] && it[0].item_at(it[1])
    end

    def first
      @first_leaf.item_at(0)
    end

    def last
      page = _last_page
      page.item_at(page.amount-1)
    end

    def shift
      if @size > 0
        res = @first_leaf.item_at(0)
        @first_leaf.delete_kv(0)
        if @first_leaf.amount < MIN
          leaf_le_fix(@first_leaf.key_at(0))
        end
        @size -= 1
        res
      end
    end

    def pop
      if @size > 0
        page = _last_page
        res = page.item_at(page.amount-1)
        page.delete_kv(page.amount-1)
        if page.amount < MIN
          leaf_le_fix(page.key_at(page.amount-1))
        end
        @size -= 1
        res
      end
    end

    def _last_page
      page = @root
      while page.inner?
        page = page.child(page)
      end
      page
    end

    def leaf_le(k)
      page = @root
      while page.inner?
        pos = _page_first_gt(page, k)
        return nil if pos == 0
        page = page.child(pos - 1)
      end
      page
    end

    def leaf_le_fix(k)
      page = @root
      while page.inner?
        pos = _page_first_gt(page, k)
        return nil if pos == 0
        pos -= 1
        child = page.child(pos)
        page = fix_page(page, pos, child, k, true)
      end
      page
    end

    def last_lt(k, fixing)
      page = @root
      while page.inner?
        pos = _page_first_ge(page, k)
        return [nil,nil] if pos == 0
        pos -= 1
        child = page.child(pos)
        if fixing
          child = fix_page(page, pos, child, k, false)
        end
        page = child
      end
      if fixing != :fix
        pos = _page_first_ge(page, k) - 1
        pos >= 0 ? [page, pos] : [nil, nil]
      end
    end

    def fix_page(page, pos, child, k, include_equal)
      if child.amount > MAX
        right = child.split_page
        page.insert_child(pos + 1, right)
        c = cmp_key(child.next.key_at(0), k)
        if include_equal ? c <= 0 : c < 0
          child = child.next
        end
      elsif child.amount < MIN
        if pos >= page.amount - 1 ||
            pos > 0 &&
            page.child(pos-1).amount < page.child(pos+1).amount
          pos = pos - 1
        end
        child = page.child(pos)
        child.join_page(page.child(pos + 1))
        page.delete_child(pos + 1)
      end
      child
    end

    def _fix_root
      if @root.amount > MAX
        left = @root
        right = @root.split_page
        @root = Inner.new
        @root.push(left, right)
      elsif @root.amount == 1 && @root.inner?
        @root = @root.child(0)
      end
    end

    def cmp_key(k1, k2)
      (@cmp_key ? @cmp_key.call(k1, k2) : k1 <=> k2) or raise ArgumentError, "could not compare #{k1.inspect} and #{k2.inspect}"
    end

    def ==(oth)
      return false unless self.class == oth.class
      return false unless @cmp_key == oth.cmp_proc
      this = [nil, nil]
      that = [nil, nil]
      while true
        _next_pos(this)
        oth._next_pos(that)
        unless this[0]
          return !that[0]
        end
        return false unless that[0]
        if this[0].item_at(this[1]) != that[0].item_at(that[1])
          return false
        end
      end
    end

    def initialize_copy(oth)
      @first_leaf = @first_leaf.dup
      @root = Inner.new
      leaf = @first_leaf
      @root << leaf
      last_inner = @root
      while nxt = leaf.next
        nxt = nxt.dup
        leaf.next = nxt
        nxt.prev = leaf
        last_inner << nxt
        if last_inner.amount > MAX
          leaf_le_fix(nxt.key_at(0))
          if last_inner.next
            last_inner = last_inner.next
          end
        end
        leaf = nxt
      end
    end

    def keep_if
      it = [nil, nil]
      while true
        _next_pos(it)
        return unless it[0]
        unless yield(*it[0].item_at(it[1]))
          it[0].delete_kv(it[1])
          it[1] -= 1
          @size -= 1
        end
      end
    end

    def _next_pos(a)
      if a[0] == nil
        a[0], a[1] = @first_leaf, 0
      else
        a[1] += 1
      end
      if a[1] >= a[0].amount
        a[0], a[1] = a[0].next, 0
      end
      a
    end

    def _prev_pos(a)
      if a[0] == nil
        a[0] = _last_page
        a[1] = a[0].amount - 1
      else
        a[1] -= 1
      end
      if a[1] < 0
        a[0] = a[0].prev
        a[1] = a[0].amount - 1
      end
      a
    end

    def _page_first_gt(page, k)
      l, r = 0, page.amount
      while l < r
        m = (l + r) / 2
        km = page.key_at(m)
        if cmp_key(km, k) <= 0
          l = m + 1
        else
          r = m
        end
      end
      l
    end

    def _page_first_ge(page, k)
      l, r = 0, page.amount
      while l < r
        m = (l + r) / 2
        km = page.key_at(m)
        if cmp_key(km, k) < 0
          l = m + 1
        else
          r = m
        end
      end
      l
    end

    class Page < Array
      def initialize
        insert(0, nil, nil)
      end
      def item_size; 1; end
      def prev;      self[0]; end
      def next;      self[1]; end
      def prev=(v);  self[0] = v; end
      def next=(v);  self[1] = v; end
      def inner?;    false; end
      def amount;    size - 2; end

      def split_page
        right = slice!(2 + (amount / 2) * item_size, size)
        right.unshift(self, self.next)
        self.next = right
        right
      end

      def join_page(right)
        concat(right[2..-1])
        self.next = right.next
        if right.next
          right.next.prev = self
        end
      end
    end

    class Inner < Page
      def key_at(i);           self[i+2].key_at(0); end
      def child(i);            self[i+2]; end
      def set_child(i, ch);    self[i+2] = ch; end
      def insert_child(i, ch); insert(i+2, ch); end
      def delete_child(i);     delete_at(i+2); end
      def inner?;              true; end
    end

    class Leaf < Page
    end

    class MapLeaf < Leaf
      def item_size;          2; end
      def key_at(i);          self[i*2+2]; end
      def value_at(i);        self[i*2+3]; end
      def item_at(i);         self[i*2+2, 2]; end
      def set_value(i, v);    self[i*2+3] = v; end
      def insert_kv(i, k, v); insert(i*2+2, k, v); end
      def amount;             (size - 2) / 2; end

      EMPTY = [].freeze
      def delete_kv(i)
        r = self[i*2+3]
        self[i*2+2, 2] = EMPTY
        r
      end

      def push_keys(from, to, out)
        to = amount if to == -1
        from *= 2
        to *= 2
        while from < to
          out << self[2+from]
          from += 2
        end
      end

      def push_values(from, to, out)
        to = amount if to == -1
        from *= 2
        to *= 2
        while from < to
          out << self[3+from]
          from += 2
        end
      end

      def push_items(from, to, out)
        to = amount if to == -1
        from *= 2
        to *= 2
        while from < to
          out << self[2+from, 2]
          from += 2
        end
      end
    end

    class SetLeaf < Leaf
      def key_at(i);          self[i+2]; end
      def value_at(i);        self[i+2]; end
      def item_at(i);         self[i+2]; end
      def set_value(i, v); end
      def insert_kv(i, k, v); insert(i+2, k); end
      def delete_kv(i);       delete_at(i); end

      def push_keys(from, to, out)
        to == amount if to == -1
        out.concat self[(2+from)...(2+to)]
      end
      alias push_values push_keys
      alias push_items push_keys
    end
  end
end
