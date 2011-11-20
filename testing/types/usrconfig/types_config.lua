local types = {
    cfg_policy = 'user', -- update|extend|asmeta|none

    a0 = { masks={ '%.a$' }, firstline={ 'a0$' } },
    a  = { masks={ '%.a$' }, firstline={ 'a$' }, weight=1 },
    a1 = { masks={ '%.a$' }, firstline={ 'a1$' }, weight=2 },
    a2 = { masks={ '%.a$' }, firstline={ 'a2$' }, weight=3 },
    a3 = { masks={ '%.a$' }, firstline={ 'a3$' }, weight=4 },
    a5 = { masks={ '%.a5$' },firstline={ 'a$' }, weight=0 },
    a6 = { masks={ '%.a6$' },firstline={ 'a$' }, weight=5 },

    none = {}
    
} --- types

return types
