import inspect, uuid, dataclasses
from datetime import datetime, date, time
from decimal import Decimal
from types import MethodType
from flask.json import JSONEncoder
from sqlalchemy.ext.declarative import DeclarativeMeta


# TODO: finish custom json decoder

def CreateEncoder(revisit_self=False, fields_to_expand=(), fields_to_remove=()):
    """
    Wrapper method for creating Custom JSON Encoders                        \n
    Allows dynamic class definition for use in json.dumps(cls=<encoder>)    \n

    :param revisit_self:        True | False
    :type revisit_self:         bool
    :param fields_to_expand:    ORM Model Fields to expand
    :type fields_to_expand:     list|tuple
    :param fields_to_remove:    ORM Model Fields to remove
    :type fields_to_remove:     list|tuple
    :return:                    A Voodoo Alchemy Encoder class
    :rtype:                     VoodooAlchemyEncoder
    """

    visited_values = []

    class VoodooAlchemyEncoder(JSONEncoder):
        """
        JSON serializer for objects not serializable by default json code                   \n
        Also adds nested serialization and dynamic field customization of database Models   \n

        -----

        The following data types are supported:

        - :class:`types.FunctionType`
        - :class:`types.MethodType`
        - :class:`dataclasses`
        - :class:`decimal.Decimal`
        - :class:`datetime.datetime`
        - :class:`datetime.date`
        - :class:`datetime.time`
        - :class:`uuid.UUID`
        - :class:`flask.Markup`
        - :class:`sqlalchemy.ext.declarative.DeclarativeMeta`
        - :class:`collections.Iterable`
        - :class:`types.GeneratorType`
        - and all classes supported by :class:`flask.JSONEncoder`
        """

        def default(self, value):
            """ Override JSONEcoder default class """

            if self.is_valid_callable(value):
                value = value()
            elif dataclasses and dataclasses.is_dataclass(value):
                value = dataclasses.asdict(value)

            if isinstance(value, Decimal):
                value.to_eng_string()

            elif isinstance(value, datetime):
                return value.strftime('%Y-%m-%d %H:%M:%S')

            elif isinstance(value, date):
                return value.strftime('%Y-%m-%d')

            elif isinstance(value, time):
                return value.strftime('%H:%M:%S')

            elif isinstance(value, uuid.UUID):
                return str(value)

            elif hasattr(value, "__html__"):
                return str(value.__html__())

            elif isinstance(value.__class__, DeclarativeMeta):
                return self.serialize_model(value)

            elif isinstance(value, dict):
                return self.serialize_dict(value)

            elif isinstance(value, list):
                return self.serialize_list(value)

            elif hasattr(value, '__iter__') and hasattr(value, '__next__'):
                return self.serialize_iter(value)

            else:
                return JSONEncoder.default(self, value)

        @staticmethod
        def is_valid_callable(func):
            if callable(func):
                i = inspect.getfullargspec(func)
                if i.args == ['self'] and isinstance(func, MethodType) and not any([i.varargs, i.varkw]):
                    return True
                return not any([i.args, i.varargs, i.varkw])
            return False

        def serialize_model(self, value):
            # don't re-visit self
            if revisit_self:
                if value in visited_values:
                    return None
                visited_values.append(value)

            # go through each field in this SQLalchemy class
            fields = {}
            for field in [x for x in dir(value) if not x.startswith('_') and x != 'metadata' and not x in fields_to_remove]:
                val = value.__getattribute__(field)

                # is this field another SQLalchemy valueect, or a list of SQLalchemy valueects?
                if isinstance(val.__class__, DeclarativeMeta) or (
                        isinstance(val, list) and len(val) > 0 and isinstance(val[0].__class__, DeclarativeMeta)):
                    # unless we're expanding this field, stop here
                    if field not in fields_to_expand:
                        # not expanding this field: set it to None and continue
                        fields[field] = None
                        continue

                # serialize each field if necessary
                val = self.default(val)
                fields[field] = val

            # a json-encodable dict
            return fields

        def serialize_iter(self, value):
            return [self.default(v) for v in value]

        def serialize_list(self, value):
            return [self.default(v) for v in value]

        def serialize_dict(self, value):
            return {self.default(k):self.default(v) for k,v in value.items()}

    return VoodooAlchemyEncoder

# class CustomJSONDecoder(JSONDecoder):
#     def __init__(self, *args, **kwargs):
#         self.orig_obj_hook = kwargs.pop("object_hook", None)
#         super(CustomJSONDecoder, self).__init__(*args,
#             object_hook=self.custom_obj_hook, **kwargs)
#
#     def custom_obj_hook(self, dct):
#         # Calling custom decode function:
#         dct = HelperFunctions.jsonDecodeHandler(dct)
#         if (self.orig_obj_hook):  # Do we have another hook to call?
#             return self.orig_obj_hook(dct)  # Yes: then do it
#         return dct  # No: just return the decoded dict
