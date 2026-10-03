package br.com.library.dto.response;

import br.com.library.entity.Autor;

public record AutorResponse(Long id, String nome, String nacionalidade) {

    public static AutorResponse de(Autor autor) {
        return new AutorResponse(autor.getId(), autor.getNome(), autor.getNacionalidade());
    }
}
