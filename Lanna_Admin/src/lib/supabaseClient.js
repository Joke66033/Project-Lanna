const getApiBase = () => {
  if (typeof window !== "undefined" && window.location.hostname === "siripaporn.lnw.mn") {
    return "https://siripaporn.lnw.mn";
  }
  return import.meta.env.VITE_API_BASE_URL || "https://siripaporn.lnw.mn";
};
const BASE = getApiBase();

class SupabaseQueryBuilder {
  constructor(table) {
    this.table = table;
    this._select = "*";
    this._count = null;
    this._filters = [];
    this._order = null;
    this._limit = null;
    this._offset = null;
  }

  select(fields = "*", opts = {}) {
    this._select = fields;
    if (opts.count) this._count = opts.count;
    return this;
  }

  eq(col, val) {
    this._filters.push(`${col}=eq.${encodeURIComponent(val)}`);
    return this;
  }

  neq(col, val) {
    this._filters.push(`${col}=neq.${encodeURIComponent(val)}`);
    return this;
  }

  ilike(col, val) {
    this._filters.push(`${col}=ilike.${encodeURIComponent(val)}`);
    return this;
  }

  or(filterStr) {
    this._filters.push(`or=${encodeURIComponent(filterStr)}`);
    return this;
  }

  order(col, opts = {}) {
    this._order = `${col}.${opts.ascending === false ? "desc" : "asc"}`;
    return this;
  }

  range(from, to) {
    this._offset = from;
    this._limit = to - from + 1;
    return this;
  }

  limit(n) {
    this._limit = n;
    return this;
  }

  async _execute() {
    try {
      const params = new URLSearchParams();
      params.set("table", this.table);
      params.set("select", this._select);
      if (this._order) params.set("order", this._order);
      if (this._limit !== null) params.set("limit", this._limit);
      if (this._offset !== null) params.set("offset", this._offset);
      this._filters.forEach((f) => {
        const parts = f.split("=");
        params.set(parts[0], parts.slice(1).join("="));
      });

      const url = `${BASE}/endpoints/supabase_proxy.php?${params.toString()}`;
      const res = await fetch(url);
      if (!res.ok) {
        return { data: [], count: 0, error: { message: `HTTP ${res.status}` } };
      }
      const json = await res.json();
      return {
        data: json.data || [],
        count: json.count ?? json.data?.length ?? 0,
        error: json.error ? { message: json.error } : null,
      };
    } catch (err) {
      return { data: [], count: 0, error: { message: err.message || String(err) } };
    }
  }

  then(onFulfilled, onRejected) {
    return this._execute().then(onFulfilled, onRejected);
  }

  catch(onRejected) {
    return this._execute().catch(onRejected);
  }
}

export const supabase = {
  from: (table) => new SupabaseQueryBuilder(table),
  channel: () => ({
    on: function () {
      return this;
    },
    subscribe: function () {
      return this;
    },
  }),
  removeChannel: () => {},
};
