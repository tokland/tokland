# Introducción #

La consulta del Diccionario de la Real Academia Española a través de su [página web](http://buscon.rae.es/draeI/) es libre, pero este servicio no es siempre suficiente; en primer lugar porque te obliga a estar conectado a Internet, y en segundo porque disponer de los datos en bruto (en forma de ficheros, base de datos o lo que sea) posibilitan análisis automatizados que de otra forma son tediosos o simplemente imposibles.

En este documento se hace un repaso de los scripts (bajo licencia GPL) necesarios para generar el diccionario localmente. Echa un vistazo al repositorio para ver cómo generar otros formatos (dictd, SQL).

# Descarga #

http://code.google.com/p/tokland/downloads/list

# Instalación #

Instrucciones para sistemas operativos UNIX:

```
$ wget http://tokland.googlecode.com/files/drae-dictd-2012_05.tgz
$ tar xvzf drae-dictd-2012_05.tgz
$ sudo cp drae.index drae.dict.dz /usr/share/dictd/
$ sudo dictdconfig --write # según me comentan, esto es necesario en Debian (y quizá en otras distribuciones)
$ sudo /etc/init.d/dictd restart # sudo /etc/rc.d/dictd restart 
```

# Fuentes #

El código (_Bash_ y _Ruby_) están en el repositorio:

```
$ svn co http://tokland.googlecode.com/svn/trunk/rae
$ cd rae
$ bash download_by_id.sh
$ ruby process_html.rb
$ bash generate_dicd.sh
```

# Miscelánea #

  * Aquí tienes una lista de palabras extraída del diccionario: [words.txt](http://tokland.googlecode.com/svn/trunk/rae/words.txt)