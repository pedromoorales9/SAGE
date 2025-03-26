/// Clase utilitaria que proporciona snippets de código para autocompletado
class CodeSnippets {
  /// Snippets de código para Python
  static final Map<String, String> python = {
    'if': '''if condition:
    pass''',
    'for': '''for item in iterable:
    pass''',
    'while': '''while condition:
    pass''',
    'try': '''try:
    # Código que puede lanzar una excepción
except Exception as e:
    # Manejar la excepción
    pass''',
    'def': '''def function_name(parameters):
    """
    Docstring explaining the function
    """
    # Function body
    return result''',
    'class': '''class ClassName:
    """
    Docstring explaining the class
    """
    
    def __init__(self, parameters):
        # Initialize instance attributes
        pass
        
    def method_name(self, parameters):
        # Method body
        pass''',
    'import': 'import module_name',
    'from': 'from module_name import name1, name2',
    'with': '''with expression as variable:
    # Block of code
    pass''',
    'lambda': 'lambda arguments: expression',
    'list_comp': '[expression for item in iterable if condition]',
    'dict_comp': '{key: value for item in iterable if condition}',
    'file_read': '''with open('filename.txt', 'r') as file:
    content = file.read()''',
    'file_write': '''with open('filename.txt', 'w') as file:
    file.write('content')''',
    'main': '''if __name__ == "__main__":
    # Code to execute when run directly
    pass''',
  };

  /// Snippets de código para PowerShell
  static final Map<String, String> powershell = {
    'if': '''if (condition) {
    # Code block
}''',
    'if-else': '''if (condition) {
    # Code block
} else {
    # Code block
}''',
    'foreach': '''foreach (\$item in \$collection) {
    # Code block
}''',
    'while': '''while (condition) {
    # Code block
}''',
    'function': '''function FunctionName {
    param (
        [Parameter(Mandatory=\$true)]
        [string]\$ParameterName
    )
    
    # Function body
    
    return \$result
}''',
    'try': '''try {
    # Code that might throw an exception
} catch {
    # Handle the exception
    Write-Error \$_.Exception.Message
} finally {
    # Code that always runs
}''',
    'param': '''param (
    [Parameter(Mandatory=\$true)]
    [string]\$ParameterName,
    
    [Parameter(Mandatory=\$false)]
    [int]\$OptionalParameter = 0
)''',
    'switch': '''switch (\$variable) {
    condition1 { # Action 1 }
    condition2 { # Action 2 }
    default { # Default action }
}''',
    'hashtable': '@{ key1 = "value1"; key2 = "value2" }',
    'file_read': '\$content = Get-Content -Path "filename.txt"',
    'file_write': 'Set-Content -Path "filename.txt" -Value "content"',
    'exec_command': '\$result = Invoke-Expression \$command',
    'get_service':
        '\$services = Get-Service | Where-Object { \$_.Status -eq "Running" }',
    'get_process':
        '\$processes = Get-Process | Sort-Object -Property CPU -Descending',
    'export_csv': '\$data | Export-Csv -Path "output.csv" -NoTypeInformation',
  };

  /// Obtiene los snippets según el lenguaje
  static Map<String, String> getSnippetsForLanguage(String language) {
    switch (language.toLowerCase()) {
      case 'python':
        return python;
      case 'powershell':
        return powershell;
      default:
        return {};
    }
  }

  /// Obtiene la lista de comandos disponibles para autocompletado según el lenguaje
  static List<String> getCommandsForLanguage(String language) {
    switch (language.toLowerCase()) {
      case 'python':
        return [
          'def ',
          'class ',
          'import ',
          'from ',
          'if ',
          'else:',
          'elif ',
          'for ',
          'while ',
          'try:',
          'except:',
          'finally:',
          'with ',
          'return ',
          'print(',
          'len(',
          'range(',
          'str(',
          'int(',
          'float(',
          'list(',
          'dict(',
          'set(',
          'tuple(',
          'sum(',
          'max(',
          'min(',
          'open(',
          'enumerate(',
          'zip(',
          'lambda ',
          'pass',
          'break',
          'continue',
          'assert ',
          'yield ',
          'global ',
          'nonlocal ',
          'is ',
          'in ',
          'not ',
          'and ',
          'or '
        ];
      case 'powershell':
        return [
          'function ',
          'if (',
          'else {',
          'elseif (',
          'foreach (',
          'while (',
          'try {',
          'catch {',
          'finally {',
          'switch (',
          'param(',
          '\$_',
          'Write-Host ',
          'Get-',
          'Set-',
          'New-',
          'Remove-',
          'Import-',
          'Export-',
          'ConvertTo-',
          'ConvertFrom-',
          'Invoke-',
          'Out-',
          'Select-',
          'Where-',
          'ForEach-',
          'Format-',
          'Measure-',
          'Test-',
          'Copy-',
          'Move-',
          'Rename-',
          'Start-',
          'Stop-',
          'Restart-',
          'Enable-',
          'Disable-',
          'Add-',
          'Update-',
          'Uninstall-',
          'Install-'
        ];
      default:
        return [];
    }
  }
}
