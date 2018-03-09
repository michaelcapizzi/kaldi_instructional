import sys
import json

# This script will parse a parameters file for use in any step of `kaldi` process (any `run_*.sh` script)
# and create a string containing *all* arguments that can be loaded to command line

# sys.argv[1] = kaldi_parameters.json
# sys.argv[2] = which `run_*.sh` script
# sys.argv[3] = parameter name

# loads a parameter `.json` string into dict
def load_parameter_json(parameter_json_string):
    return json.loads(parameter_json_string)


# converts all keys and values to command-line string
def convert_to_commandline_string(parameter_json_dict, required_key):
    # initialize final string
    final_string = ""
    # find the relevant script
    for script_key in parameter_json_dict.keys():
        # for the relevant script only
        if script_key in required_key:
            # get parameters
            all_parameters = parameter_json_dict[script_key]["parameters"]
            # iterate through parameters, adding to string
            for param in all_parameters.keys():
                value = all_parameters[param]["value"]
                # if there is a value
                if value:
                    flag = all_parameters[param]["flag"]
                    # if a boolean
                    if isinstance(value, bool):
                        # just append flag to string
                        final_string = final_string + " " + flag
                    else:
                        # append flag and value to string
                        final_string = final_string + " " + flag + " " + value
    return final_string


# retrieve value for one particular parameter
def retrieve_value(parameter_json_dict, required_key, param_name):
    # initialize final param value
    final_param_value = None
    # find the relevant script
    for script_key in parameter_json_dict.keys():
        # for the relevant script only
        if script_key in required_key:
            relevant_param = parameter_json_dict[script_key]["parameters"][param_name]
            final_param_value = relevant_param["value"]

    if isinstance(final_param_value, bool):
        # to make sure `bash` boolean is understood, lowercase `python` boolean string
        return str(final_param_value).lower()
    elif final_param_value == 0:
        return str(0)
    elif not final_param_value:
        # if null/None, return ""
        return ""
    else:
        return str(final_param_value)

############################################

if __name__ == "__main__":

    with open(sys.argv[1], "r") as param_file:
        param_json_string = param_file.read()

    param_json_dict = load_parameter_json(param_json_string)

    # command_line_string = convert_to_commandline_string(param_json_dict, sys.argv[2])
    #
    # print(command_line_string)
    #

    if len(sys.argv) == 4:
        single_param_string = retrieve_value(param_json_dict, sys.argv[2], sys.argv[3])
        print(single_param_string)
    elif len(sys.argv) == 3:
        for script_key in param_json_dict:
            if script_key in sys.argv[2]:
                print(str(param_json_dict[script_key]))
