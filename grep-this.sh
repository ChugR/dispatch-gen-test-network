#!/bin/bash

echo "Find core threads"
find . -name "A*.txt" | sort | xargs grep -m1 core_thread

echo "Find worker threads"
find . -name "A*.txt" | sort | xargs grep -m1 process_connector | sort

echo "Find core thread top hitter"
find . -name "A*.txt" | sort | xargs grep -m1 -A2 core_thread

echo "Find all delete_delivry calls"
find . -name "A*.txt" | sort | xargs grep -m1 -A2 delete_delivery

echo "Core thread delete delivery calls"
find . -name "A*.txt" | sort | xargs grep -m1 -A2 delete_delivery_CT

echo "Specialty things we care about"
find . -name "A*.txt" | sort | xargs grep -m1 -A2 qd_message_free
find . -name "A*.txt" | sort | xargs grep -m1 -A2 qd_message_copy
