const getApiBase = () => {
  if (typeof window !== "undefined" && window.location.hostname === "siripaporn.lnw.mn") {
    return "https://siripaporn.lnw.mn";
  }
  return import.meta.env.VITE_API_BASE_URL || "https://siripaporn.lnw.mn";
};
const BASE = getApiBase();

export const supabase = {
  from: (table) => {
    const builder = {
      _select: "*",
      _count: null,
      _filters: [],
      _order: null,
      _limit: null,

      select(fields = "*", opts = {}) {
        this._select = fields;
        if (opts.count) this._count = opts.count;
        return this;
      },
      eq(col, val) {
        this._filters.push(`${col}=eq.${encodeURIComponent(val)}`);
        return this;
      },
      neq(col, val) {
        this._filters.push(`${col}=neq.${encodeURIComponent(val)}`);
        return this;
      },
      ilike(col, val) {
        this._filters.push(`${col}=ilike.${encodeURIComponent(val)}`);
        return this;
      },
      order(col, opts = {}) {
        this._order = `${col}.${opts.ascending === false ? "desc" : "asc"}`;
        return this;
      },
      range(from, to) {
        this._limit = to - from + 1;
        return this;
      },
      limit(n) {
        this._limit = n;
        return this;
      },
      async then(resolve, reject) {
        try {
          const params = new URLSearchParams();
          params.set("table", table);
          params.set("select", this._select);
          if (this._order) params.set("order", this._order);
          if (this._limit) params.set("limit", this._limit);
          this._filters.forEach((f) => {
            const [k, v] = f.split("=");
            params.set(k, v);
          });

          const url = `${BASE}/endpoints/supabase_proxy.php?${params.toString()}`;
          const res = await fetch(url);
          const json = await res.json();
          resolve({ data: json.data || [], count: json.count ?? json.data?.length ?? 0, error: json.error });
        } catch (err) {
          resolve({ data: [], count: 0, error: err });
        }
      },
    };
    return builder;
  },
  channel: () => ({
    on: function () {
      return this;
    },
    subscribe: function () {
      return this;
    },
  }),
};
