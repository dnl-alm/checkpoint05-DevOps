package br.com.library.dto.response;

import br.com.library.entity.Livro;

public record LivroResponse(Long id, String titulo, Integer anoPublicacao, AutorResponse autor) {

    public static LivroResponse de(Livro livro) {
        return new LivroResponse(
                livro.getId(),
                livro.getTitulo(),
                livro.getAnoPublicacao(),
                AutorResponse.de(livro.getAutor())
        );
    }
}
