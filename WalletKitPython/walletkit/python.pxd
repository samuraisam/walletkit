cdef extern from "Python.h":
    const char *PyUnicode_AsUTF8(object unicode)
    object PyUnicode_FromString(const char *u)
    object PyBytes_FromStringAndSize(const char *v, size_t len)
    void Py_INCREF(object o)
    void Py_DECREF(object o)
    long PyLong_AsLong(object o)
    size_t PyLong_AsSize_t(object o)
    object PyLong_FromUnsignedLong(long v)