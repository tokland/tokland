#!/usr/bin/python
"""
Convert UTM to/from Latitude/Longitude coordinates (Datum configurable)

Original Perl Code (UTM.pm) - Graham Crookham. Copyright (c) 2000,2002,2004

Translated to Python by Arnau Sanchez <tokland@gmail.com>
"""

from math import sqrt, sin, cos, tan, pi, ceil
import sys

# TODO: mgsr_to_XXX and XXX_to_mgrs functions
# TODO: Example and docstrings

__all__ = ["latlon_to_utm", "utm_to_latlon", "utm_to_mgrs",
    "latlon_to_mgrs", "mgrs_to_utm", "mgrs_to_latlon",
    "ellipsoid_info", "ellipsoid_names"]

__version__ = "0.06-ehas"

# Global definitions

utm_letters = "CDEFGHJKLMNPQRSTUVWXX"

_ellipsoids = [
    ("Airy", 6377563, 0.00667054),
    ("Australian National", 6378160, 0.006694542),
    ("Bessel 1841", 6377397, 0.006674372),
    ("Bessel 1841 (Nambia) ", 6377484, 0.006674372),
    ("Clarke 1866", 6378206, 0.006768658),
    ("Clarke 1880", 6378249, 0.006803511),
    ("Everest", 6377276, 0.006637847),
    ("Fischer 1960 (Mercury)", 6378166, 0.006693422),
    ("Fischer 1968", 6378150, 0.006693422),
    ("GRS 1967", 6378160, 0.006694605),
    ("GRS 1980", 6378137, 0.00669438),
    ("Helmert 1906", 6378200, 0.006693422),
    ("Hough", 6378270, 0.00672267),
    ("International", 6378388, 0.00672267),
    ("Krassovsky", 6378245, 0.006693422),
    ("Modified Airy", 6377340, 0.00667054),
    ("Modified Everest", 6377304, 0.006637847),
    ("Modified Fischer 1960", 6378155, 0.006693422),
    ("South American 1969", 6378160, 0.006694542),
    ("WGS-60", 6378165, 0.006693422),
    ("WGS-66", 6378145, 0.006694542),
    ("WGS-72", 6378135, 0.006694318),
    ("WGS-84", 6378137, 0.00669438),
]

ellipsoids = dict((name, (rad, ecc)) for (name, rad, ecc) in _ellipsoids)

# Private functions

def _valid_utm_zone(zone_letter):
    return (zone_letter in utm_letters)

def _get_interval(limits, n):
    for index, limit in enumerate(limits):
        if n < limit:
            return index

# Public interface

def deg2rad(angle):
    return angle * (pi / 180.0)

def rad2deg(angle):
    return angle * (180.0 / pi)

def ellipsoid_names():
    return sorted(ellipsoids.keys())

def ellipsoid_info(name):
    try:
        return ellipsoids[name]
    except KeyError:
        raise KeyError, "Unknown datum: %s" % name

def latlon_to_utm(ellips, latitude, longitude):
    radius, eccentricity = ellipsoid_info(ellips)
    if longitude < -180 or longitude > 180:
        raise ValueError, "Longitude invalid"

    long2 = longitude - int((longitude + 180)/360) * 360
    zone = int((long2 + 180)/6) + 1
    lat_radian  = deg2rad(latitude)
    long_radian = deg2rad(long2)
    k0 = 0.9996   # scale

    if 56.0 <= latitude < 64.0 and 3.0 <= long2 < 12.0:
        zone = 32
    if latitude >= 72.0 and latitude < 84.0:
        if 0 <= long2 < 42:
            limits = (0, 9, 21, 33, 42)
            zone = 31 + 2*(_get_interval(limits, long2)-1)

    longorigin = (zone - 1) * 6 - 180 + 3
    longoriginradian = deg2rad(longorigin)
    eccentprime = eccentricity / (1 - eccentricity)

    N = radius / sqrt(1-eccentricity * sin(lat_radian)*sin(lat_radian))
    T = tan(lat_radian) * tan(lat_radian)
    C = eccentprime * cos(lat_radian) * cos(lat_radian)
    A = cos(lat_radian) * (long_radian - longoriginradian)
    M = radius * ((1 - eccentricity/4 - 3 * eccentricity * eccentricity/64
        - 5 * eccentricity * eccentricity * eccentricity/256) * lat_radian
        - (3 * eccentricity/8 + 3 * eccentricity * eccentricity/32
        + 45 * eccentricity * eccentricity * eccentricity/1024) * sin(2 * lat_radian)
        + (15 * eccentricity * eccentricity/256
        + 45 * eccentricity * eccentricity * eccentricity/1024) * sin(4 * lat_radian)
        - (35 * eccentricity * eccentricity * eccentricity/3072) * sin(6 * lat_radian))

    utm_easting = (k0*N*(A+(1-T+C)*A*A*A/6
       + (5-18*T+T*T+72*C-58*eccentprime)*A*A*A*A*A/120)
       + 500000.0)
    utm_northing = (k0 * ( M + N*tan(lat_radian) *
        ( A*A/2+(5-T+9*C+4*C*C)*A*A*A*A/24 +
        (61-58*T+T*T+600*C-330*eccentprime) * A*A*A*A*A*A/720)))
    if latitude < 0:
        utm_northing += 10000000.0
    if latitude >= 84 or latitude <= -80:
        raise ValueError, "Latitude out out UTM range: %s" % latitude
    utm_letter = utm_letters[int(ceil(latitude / 8) + 9)]
    strzone = str(zone) + utm_letter
    return strzone, utm_easting, utm_northing

def utm_to_latlon(ellips, zone, easting, northing):
    radius, eccentricity = ellipsoid_info(ellips)
    zone_number, zone_letter = int(zone[:-1]), zone[-1]
    if not _valid_utm_zone(zone_letter):
        raise ValueErorr, "UTM zone (%s) invalid" % zone_letter

    k0 = 0.9996
    x  = easting - 500000 # Remove Longitude offset
    y  = northing
    # Set hemisphere (1=Northern, 0=Southern)
    hemisphere = (zone_letter >= 'N')
    if not hemisphere:
        y -= 10000000.0 # Remove Southern Offset

    longorigin = (zone_number - 1)*6 - 180 + 3
    eccPrimeSquared = (eccentricity)/(1-eccentricity)
    M  = y/k0
    mu = M/(radius*(1-eccentricity/4-3*eccentricity*
        eccentricity/64-5*eccentricity*eccentricity*eccentricity/256))

    e1 = (1-sqrt(1-eccentricity))/(1+sqrt(1-eccentricity))
    phi1rad = mu+(3*e1/2-27*e1*e1*e1/32)*sin(2*mu)+ \
        (21*e1*e1/16-55*e1*e1*e1*e1/32)*sin(4*mu)+(151*e1*e1*e1/96)*sin(6*mu)
    phi1 = rad2deg(phi1rad)
    N1 = radius/sqrt(1-eccentricity*sin(phi1rad)*sin(phi1rad))
    T1 = tan(phi1rad)*tan(phi1rad)
    C1 = eccentricity*cos(phi1rad)*cos(phi1rad)
    R1 = radius * (1-eccentricity) / \
        ((1-eccentricity*sin(phi1rad)*sin(phi1rad))**1.5)
    D = x/(N1*k0)

    Latitude = phi1rad-(N1*tan(phi1rad)/R1)*(D*D/2
        - (5+3*T1+10*C1-4*C1*C1-9*eccPrimeSquared)*D*D*D*D/24
        + (61+90*T1+298*C1+45*T1*T1-252*eccPrimeSquared-3*C1*C1)*D*D*D*D*D*D/720)
    Latitude = rad2deg(Latitude)

    Longitude = (D-(1+2*T1+C1)*D*D*D/6 +
        (5-2*C1+28*T1-3*C1*C1 +
        8*eccPrimeSquared+24*T1*T1)*D*D*D*D*D/120)/cos(phi1rad)
    Longitude = longorigin + rad2deg(Longitude)

    return Latitude, Longitude

def get_utm_from_string(s):
    sp = s.split()
    if len(sp) == 3:
        zone, easting, northing = sp
    elif len(sp) == 4:
        zone, easting, northing = sp[0]+sp[1], sp[2], sp[3]
    else:
        raise ValueError, "Cannot parse UTM string: %s" % s
    return zone, int(easting), int(northing)

def get_latlon_from_string(s):
    sp = map(float, s.replace(",", "").split())
    if len(sp) != 2:
        raise ValueError, "Cannot parse Latitude/Longitude string: %s" % s
    return sp

def main(args):
    import optparse
    default_datum = "WGS-84"
    datums_list = ", ".join(("'%s'"%s for s in ellipsoid_names()))
    usage = """usage: utm [OPTIONS]

    Convert UTM to/from Latitude/Longitude coordinates (default datum: %s)

    Supported datums: %s""" %(default_datum, datums_list)
    parser = optparse.OptionParser(usage, version=__version__)
    parser.add_option('-v', '--verbose', dest='vlevel', action="count",
        default=0, help='Increase verbose level (0=Error, 1=Info, 2=Debug)')
    parser.add_option('-u', '--utm-to-latlon', dest='utm_to_latlon',
        default=None, metavar="UTM COORDS", type="string",
        help='Convert UTM COORDS to Latitude/Longitude')
    parser.add_option('-l', '--latlon-to-utm', dest='latlon_to_utm',
        default=None, metavar="LATLON COORDS", type="string",
        help='Convert LATLON COORDS to UTM coords')
    parser.add_option('-d', '--datum', dest='datum', default=default_datum,
        metavar="DATUM_NAME", type="string",
        help='Use given datum (default: WGS-84)')

    options, args0 = parser.parse_args(args)
    datum = options.datum
    if options.utm_to_latlon:
        zone, easting, northing = get_utm_from_string(options.utm_to_latlon)
        latitude, longitude = utm_to_latlon(datum, zone, easting, northing)
        print latitude, longitude
    elif options.latlon_to_utm:
        latitude, longitude = get_latlon_from_string(options.latlon_to_utm)
        zone, easting, northing = latlon_to_utm(datum, latitude, longitude)
        print zone, easting, northing
    else:
        parser.print_help()

if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
