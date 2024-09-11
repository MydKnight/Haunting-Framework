# Haunting-Framework
Automated Management for a Haunt driven by Raspberry Pi's managed through ansible. 
Node Red will control the timing and scripting of events that will happen
Scripting of individial actions will be programmed in Python where possible
Logging of errors will be stored locally using PythonLog and replicated to an error handling framework as a future state

# Ansible Commands
Ping all hosts: "docker run -it --rm -v "$(pwd)/ansible:/ansible"  ansible-container ansible all -m ping -i /ansible/inventory/hosts"
