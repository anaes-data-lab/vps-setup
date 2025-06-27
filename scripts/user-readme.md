# Welcome to JupyterHub at the RCH Data Lab!

This environment is powered by **The Littlest JupyterHub (TLJH)**, providing a lightweight, collaborative interface for data science in Python (and R).

You can write and run code in your browser using **Jupyter Notebooks**, explore data, create plots, and share your results — all without needing to install software on your own machine.

## Getting Started

- Launch a new **Notebook** from the Jupyter interface (look for `Python 3` or `R` under the "Launcher").
- Use **code cells** to write Python code, and **markdown cells** to document your work.

Example:

```python
# Simple data manipulation with pandas
import pandas as pd

df = pd.read_csv('your_data.csv')
df.head()
```

```python
# Plotting with matplotlib
import matplotlib.pyplot as plt

df['column_name'].hist()
plt.show()
```

## Shared Resources

Your home directory is private to you. Shared datasets or notebooks may be found in:

- `shared/` — for collaborative editing (everyone can write)
- `datasets/` — read-only access to common reference datasets

## Installing Python Packages

If you are an **admin** and want to install a package for **all users**, use:

```bash
sudo -E pip install numpy
```

If you are a **regular user**, you can still install packages temporarily using:
```bash
%pip install --user numpy
```

Note: This will only persist for your account and kernel session.

## Tips

- Save notebooks regularly (`Ctrl+S`)
- Use `Restart Kernel` if code stops responding
- Use the **terminal** (from the launcher) for advanced tasks like installing packages
- Notebooks are saved as `.ipynb` files and can be downloaded or shared via GitHub

## Support

If you run into issues or need help getting started, contact your administrator or team lead.

---

Happy coding!
