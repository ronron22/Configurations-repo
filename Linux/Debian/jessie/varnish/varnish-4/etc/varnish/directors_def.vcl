/*  */
sub vcl_init {
    new www_director = directors.fallback();
    www_director.add_backend(www1);
    www_director.add_backend(www2);
}
